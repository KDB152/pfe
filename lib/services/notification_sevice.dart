import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/sensor_data_model.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static List<Alert> notifications = [];

  static Future<void> initialize() async {
    // Demander la permission pour les notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Gérer les notifications en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'Received a message while in foreground: ${message.notification?.title}',
      );
      if (message.notification != null) {
        final alert = Alert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification!.title ?? 'Alerte',
          description: message.notification!.body ?? 'Aucune description',
          timestamp: DateTime.now(),
          type: _mapMessageToAlertType(message),
        );
        notifications.add(alert);
      }
    });

    // Gérer les notifications lorsque l'application est ouverte depuis une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked: ${message.notification?.title}');
      if (message.notification != null) {
        final alert = Alert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification!.title ?? 'Alerte',
          description: message.notification!.body ?? 'Aucune description',
          timestamp: DateTime.now(),
          type: _mapMessageToAlertType(message),
        );
        notifications.add(alert);
      }
    });

    // Récupérer le token FCM
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  static AlertType _mapMessageToAlertType(RemoteMessage message) {
    if (message.data.containsKey('type')) {
      switch (message.data['type']) {
        case 'smoke':
          return AlertType.smoke;
        case 'co2':
          return AlertType.co2;
        case 'test':
          return AlertType.test;
        case 'falseAlarm':
          return AlertType.falseAlarm;
        case 'systemFailure':
          return AlertType.systemFailure;
        default:
          return AlertType.info;
      }
    }
    return AlertType.info;
  }
}
