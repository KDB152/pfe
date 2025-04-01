import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Alert> _notifications = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  Future<void> _getUserEmail() async {
    final email = _authService.getCurrentUserEmail();
    setState(() {
      _userEmail = email;
    });
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_userEmail == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les alertes système (capteurs, etc.)
      final List<Alert> systemAlerts = await _loadSystemAlerts();
      
      // Récupérer les notifications de réponses d'administrateur depuis Firestore
      final userNotificationsSnapshot = await _firestore
          .collection('user_notifications')
          .where('userEmail', isEqualTo: _userEmail)
          .orderBy('timestamp', descending: true)
          .get();

      final adminResponses = userNotificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Alert(
          id: doc.id,
          title: data['title'] ?? 'Réponse de l\'administrateur',
          description: data['description'] ?? '',
          timestamp: data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate() 
              : DateTime.now(),
          type: AlertType.adminResponse,
          isRead: data['isRead'] ?? false,
          commentId: data['commentId'],
          adminResponse: data['description'],
        );
      }).toList();

      // Combiner les alertes système et les réponses de l'admin
      final allNotifications = [...systemAlerts, ...adminResponses];
      
      // Trier par date (plus récente en premier)
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _notifications = allNotifications;
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

  Future<List<Alert>> _loadSystemAlerts() async {
    // Simulation de récupération d'alertes système
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return [
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
  }

  Future<void> _markAsRead(String notificationId) async {
    // Pour les notifications Firebase, mettre à jour le statut dans Firestore
    if (notificationId.length > 5) { // Supposons que les IDs Firebase sont plus longs
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }

    // Pour les alertes système (simulées), mettre à jour localement
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        if (_notifications[i].id == notificationId) {
          // Créer une nouvelle alerte avec isRead = true
          final updatedAlert = Alert(
            id: _notifications[i].id,
            title: _notifications[i].title,
            description: _notifications[i].description,
            timestamp: _notifications[i].timestamp,
            type: _notifications[i].type,
            isRead: true,
            commentId: _notifications[i].commentId,
            adminResponse: _notifications[i].adminResponse,
          );
          
          // Remplacer l'ancienne alerte
          _notifications[i] = updatedAlert;
          break;
        }
      }
    });
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
      case AlertType.adminResponse:
        iconData = Icons.message;
        iconColor = Colors.green;
        break;
      case AlertType.info:
      default:
        iconData = Icons.info;
        iconColor = Colors.blue;
        break;
    }

    final dateFormat = _formatDate(notification.timestamp);
    final bool isUnread = !notification.isRead;

