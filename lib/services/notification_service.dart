import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_data_model.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  DatabaseReference? _alertsRef;
  bool _isListening = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final List<Alert> _notifications = [];
  List<Alert> get notifications => _notifications;
  bool _needsNotify = false;
  final Set<String> _processedAlertIds = {};

  Future<void> initialize() async {
    if (_isListening) return;

    try {
      // Initialiser Firebase Messaging
      await _firebaseMessaging.requestPermission();
      await _firebaseMessaging.getToken();

      // Initialiser les notifications locales
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Configurer les notifications en arrière-plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (FirebaseAuth.instance.currentUser != null) {
          _showNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Gérer l'ouverture de l'application via la notification
      });

      // Configurer l'écoute des alertes Firebase
      _alertsRef = FirebaseDatabase.instance.ref('alerts');
      await _loadInitialAlerts();
      _setupListener();
      _isListening = true;

      // Démarrer un timer pour debounce les notifications
      _debounceNotifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de NotificationService: $e');
    }
  }

  void _debounceNotifyListeners() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_needsNotify) {
        _needsNotify = false;
        notifyListeners();
      }
      return _isListening;
    });
  }

  Future<void> _loadInitialAlerts() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      final snapshot =
          await _alertsRef!.orderByChild('timestamp').limitToLast(50).get();
      if (snapshot.exists) {
        final alertsData = Map<String, dynamic>.from(snapshot.value as Map);
        final loadedNotifications = await compute(_parseAlerts, alertsData);

        _notifications.clear();
        _notifications.addAll(loadedNotifications);
        _processedAlertIds.addAll(loadedNotifications.map((alert) => alert.id));
        _needsNotify = true;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement initial des alertes: $e');
    }
  }

  static List<Alert> _parseAlerts(Map<String, dynamic> alertsData) {
    final List<Alert> loadedNotifications = [];
    alertsData.forEach((key, value) {
      final alertData = Map<String, dynamic>.from(value);
      if (alertData['isActive'] == true) {
        loadedNotifications.add(
          Alert(
            id: key,
            title: alertData['title'] ?? 'Alerte',
            description: alertData['description'] ?? 'Alerte détectée',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              alertData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            type: _getAlertTypeFromString(alertData['type'] ?? 'info'),
          ),
        );
      }
    });
    loadedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return loadedNotifications;
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigTextStyleInformation(''),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: Colors.deepOrange,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Alerte',
      message.notification?.body ?? 'Nouvelle alerte détectée',
      platformChannelSpecifics,
    );
  }

  Future<void> sendThresholdNotification(String title, String body) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: body,
      timestamp: DateTime.now(),
      type:
          title.contains('Température')
              ? AlertType.temperature
              : title.contains('Humidité')
              ? AlertType.humidity
              : AlertType.info,
    );

    try {
      await FirebaseDatabase.instance.ref('alerts').child(alert.id).set({
        'title': alert.title,
        'description': alert.description,
        'timestamp': alert.timestamp.millisecondsSinceEpoch,
        'type': alert.type.toString().split('.').last,
        'isActive': true,
        'notified': false,
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'écriture de l\'alerte dans Firebase: $e');
    }

    if (!_processedAlertIds.contains(alert.id)) {
      addNotification(alert);
      _processedAlertIds.add(alert.id);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'threshold_channel',
            'Threshold Notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            styleInformation: BigTextStyleInformation(''),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            color: Colors.deepOrange,
            enableLights: true,
            ledColor: Colors.deepOrange,
            ledOnMs: 1000,
            ledOffMs: 500,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        1,
        title,
        body,
        platformChannelSpecifics,
      );
    }
  }

  void _setupListener() {
    _alertsRef?.onChildAdded.listen(
      (event) {
        if (event.snapshot.value != null &&
            FirebaseAuth.instance.currentUser != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['isActive'] == true) {
            final alert = Alert(
              id: event.snapshot.key ?? '',
              title: data['title'] ?? 'Alerte',
              description: data['description'] ?? 'Nouvelle alerte détectée',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              ),
              type: _getAlertTypeFromString(data['type'] ?? 'info'),
            );

            if (!_processedAlertIds.contains(alert.id)) {
              addNotification(alert);
              _processedAlertIds.add(alert.id);

              showOverlayNotification((context) {
                return _buildNotificationCard(context, alert);
              }, duration: const Duration(seconds: 3));
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Erreur dans onChildAdded: $error');
      },
    );

    _alertsRef?.onChildChanged.listen(
      (event) {
        if (event.snapshot.value != null &&
            FirebaseAuth.instance.currentUser != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['isActive'] == true && data['notified'] != true) {
            final alert = Alert(
              id: event.snapshot.key ?? '',
              title: data['title'] ?? 'Alerte',
              description: data['description'] ?? 'Nouvelle alerte détectée',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              ),
              type: _getAlertTypeFromString(data['type'] ?? 'info'),
            );

            final index = notifications.indexWhere((n) => n.id == alert.id);
            if (index != -1) {
              updateNotification(index, alert);
            } else if (!_processedAlertIds.contains(alert.id)) {
              addNotification(alert);
              _processedAlertIds.add(alert.id);
            }

            showOverlayNotification((context) {
              return _buildNotificationCard(context, alert);
            }, duration: const Duration(seconds: 3));

            _alertsRef?.child(event.snapshot.key!).update({'notified': true});
          }
        }
      },
      onError: (error) {
        debugPrint('Erreur dans onChildChanged: $error');
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, Alert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SafeArea(
        child: ListTile(
          leading: _buildAlertIcon(alert.type),
          title: Text(
            alert.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            alert.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            OverlaySupportEntry.of(context)?.dismiss();
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed('/alert-details', arguments: alert);
          },
        ),
      ),
    );
  }

  Widget _buildAlertIcon(AlertType type) {
    final IconData iconData;
    final Color iconColor;

    switch (type) {
      case AlertType.smoke:
        iconData = Icons.smoke_free;
        iconColor = Colors.red;
        break;
      case AlertType.co2:
        iconData = Icons.whatshot;
        iconColor = Colors.orange;
        break;
      case AlertType.test:
        iconData = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      case AlertType.falseAlarm:
        iconData = Icons.warning;
        iconColor = Colors.amber;
        break;
      case AlertType.systemFailure:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case AlertType.info:
      default:
        iconData = Icons.info;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  static AlertType _getAlertTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'smoke':
        return AlertType.smoke;
      case 'co2':
        return AlertType.co2;
      case 'test':
        return AlertType.test;
      case 'falsealarm':
        return AlertType.falseAlarm;
      case 'systemfailure':
        return AlertType.systemFailure;
      case 'humidity':
        return AlertType.humidity;
      case 'temperature':
        return AlertType.temperature;
      case 'info':
      default:
        return AlertType.info;
    }
  }

  void addNotification(Alert alert) {
    _notifications.insert(0, alert);
    _needsNotify = true;
  }

  void updateNotification(int index, Alert alert) {
    _notifications[index] = alert;
    _needsNotify = true;
  }

  void clearNotifications() {
    _notifications.clear();
    _processedAlertIds.clear();
    _needsNotify = true;
  }
}
