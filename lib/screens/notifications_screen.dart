import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Alert> _notifications = [];
  bool _isLoading = true;
  late DatabaseReference _alertsRef;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeAlertsListener();
  }

  @override
  void dispose() {
    _alertsRef.onValue.drain();
    super.dispose();
  }

  void _setupRealtimeAlertsListener() {
    // Référence à la base de données Firebase Realtime
    _alertsRef = FirebaseDatabase.instance.ref('alerts');

    // Écouter les mises à jour en temps réel
    _alertsRef.onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          final alertsData = Map<String, dynamic>.from(
            event.snapshot.value as Map,
          );

          alertsData.forEach((key, value) {
            final alertData = Map<String, dynamic>.from(value);

            // Vérifier si l'alerte est active
            if (alertData['isActive'] == true) {
              final alert = Alert(
                id: key,
                title: alertData['title'] ?? 'Alerte',
                description:
                    alertData['description'] ?? 'Nouvelle alerte détectée',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  alertData['timestamp'] ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
                type: _getAlertTypeFromString(alertData['type'] ?? 'info'),
              );

              // Afficher la notification temporaire
              _showTemporaryNotification(alert);

              // Ajouter à la liste des notifications si elle n'existe pas déjà
              if (!_notifications.any((n) => n.id == alert.id)) {
                setState(() {
                  _notifications.insert(0, alert);
                });
              }
            }
          });
        }
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion à la base de données: $error'),
          ),
        );
      },
    );
  }

  void _showTemporaryNotification(Alert alert) {
    // Utilise la bibliothèque overlay_support pour afficher les notifications en haut
    showOverlayNotification(
      (context) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SafeArea(
            child: ListTile(
              leading: _buildAlertIcon(alert.type),
              title: Text(
                alert.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                alert.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                OverlaySupportEntry.of(context)?.dismiss();
                // Naviguer vers les détails de la notification
                Navigator.pushNamed(
                  context,
                  '/alert-details',
                  arguments: alert,
                );
              },
            ),
          ),
        );
      },
      duration: const Duration(
        seconds: 3,
      ), // La notification disparaît après 3 secondes
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

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'historique des notifications depuis Firebase
      final snapshot = await FirebaseDatabase.instance.ref('alerts').get();

      if (snapshot.exists) {
        final List<Alert> loadedNotifications = [];
        final alertsData = Map<String, dynamic>.from(snapshot.value as Map);

        alertsData.forEach((key, value) {
          final alertData = Map<String, dynamic>.from(value);

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
        });

        // Trier par date (plus récente en premier)
        loadedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _notifications = loadedNotifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des notifications: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepOrange,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              )
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child:
                    _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return _buildNotificationItem(notification);
                          },
                        ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez aucune notification pour le moment.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Alert notification) {
    final dateFormat = _formatDate(notification.timestamp);

    return InkWell(
      onTap: () {
        // Naviguer vers les détails de la notification
        Navigator.pushNamed(context, '/alert-details', arguments: notification);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertIcon(notification.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
