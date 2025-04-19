import 'package:firebase_database/firebase_database.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  DatabaseReference? _alertsRef;
  bool _isListening = false;

  void initialize() {
    if (!_isListening) {
      _alertsRef = FirebaseDatabase.instance.ref('alerts');
      _setupListener();
      _isListening = true;
    }
  }

  void _setupListener() {
    _alertsRef?.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Vérifier si l'alerte est active
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

          // Afficher la notification
          showOverlayNotification((context) {
            return _buildNotificationCard(context, alert);
          }, duration: const Duration(seconds: 3));
        }
      }
    });

    // Écouter aussi les changements pour les alertes existantes qui deviennent actives
    _alertsRef?.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Vérifier si l'alerte vient de devenir active
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

          // Afficher la notification
          showOverlayNotification((context) {
            return _buildNotificationCard(context, alert);
          }, duration: const Duration(seconds: 3));

          // Mettre à jour que l'alerte a été notifiée
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
