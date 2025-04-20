import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  DatabaseReference? _alertsRef;
  bool _isListening = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Liste pour stocker les notifications à afficher dans notifications_screen
  final List<Alert> _notifications = [];
  List<Alert> get notifications => _notifications;

  Future<void> initialize() async {
    if (!_isListening) {
      // Initialiser Firebase Messaging
      await _firebaseMessaging.requestPermission();
      await _firebaseMessaging.getToken();

      // Initialiser les notifications locales avec un style moderne
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Configurer les notifications en arrière-plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Gérer l'ouverture de l'application via la notification
      });

      // Configurer l'écoute des alertes Firebase
      _alertsRef = FirebaseDatabase.instance.ref('alerts');
      _setupListener();
      _isListening = true;
    }
  }

  // Méthode pour afficher une notification locale avec un design moderne
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

  // Méthode pour envoyer une notification manuellement avec un design moderne
  Future<void> sendThresholdNotification(String title, String body) async {
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

    // Créer une alerte à partir de la notification
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: body,
      timestamp: DateTime.now(),
      type:
          title.contains('Température')
              ? AlertType.temperature
              : AlertType.humidity,
    );

    // Ajouter la notification à la liste
    _notifications.insert(
      0,
      alert,
    ); // Insérer au début pour afficher les plus récentes en haut

    // Afficher la notification
    await _flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _setupListener() {
    _alertsRef?.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
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

          // Afficher la notification via overlay
          showOverlayNotification((context) {
            return _buildNotificationCard(context, alert);
          }, duration: const Duration(seconds: 3));

          // Envoyer une notification push et l'ajouter à la liste
          sendThresholdNotification(alert.title, alert.description);
        }
      }
    });

    _alertsRef?.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
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

          showOverlayNotification((context) {
            return _buildNotificationCard(context, alert);
          }, duration: const Duration(seconds: 3));

          sendThresholdNotification(alert.title, alert.description);

          _alertsRef?.child(event.snapshot.key!).update({'notified': true});
        }
      }
    });
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

  AlertType _getAlertTypeFromString(String typeStr) {
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
      case 'info':
      default:
        return AlertType.info;
    }
  }

  void dispose() {
    _isListening = false;
  }
}
