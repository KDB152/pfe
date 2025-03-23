import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Alert> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulez une récupération de notifications
      await Future.delayed(const Duration(seconds: 1));

      final now = DateTime.now();

      setState(() {
        _notifications = [
          Alert(
            id: '1',
            title: 'Test du système',
            description:
                'Test de routine du système de détection d\'incendie complété avec succès.',
            timestamp: DateTime(now.year, now.month, now.day, 8, 23),
            type: AlertType.test,
          ),
          Alert(
            id: '2',
            title: 'Alerte de fumée',
            description:
                'Détection de fumée dans la cuisine. Vérification effectuée: fausse alerte.',
            timestamp: DateTime(now.year, now.month, now.day - 4, 14, 17),
            type: AlertType.falseAlarm,
          ),
          Alert(
            id: '3',
            title: 'Batterie faible',
            description:
                'Le niveau de batterie du détecteur est bas. Veuillez remplacer les piles.',
            timestamp: DateTime(now.year, now.month, now.day - 7, 9, 45),
            type: AlertType.systemFailure,
          ),
        ];
        _isLoading = false;
      });
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
    final IconData iconData;
    final Color iconColor;

    switch (notification.type) {
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

    final dateFormat = _formatDate(notification.timestamp);

    return InkWell(
      onTap: () {
        // Naviguer vers les détails de la notification
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
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
