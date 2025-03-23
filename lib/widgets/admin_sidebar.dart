// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/user_management_screen.dart';
import '../screens/users_comments_screen.dart';

class AdminSidebar extends StatelessWidget {
  final String userEmail;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final AuthService _authService = AuthService();

  AdminSidebar({
    super.key,
    required this.userEmail,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<bool>(
        future: _authService.isAdmin(),
        builder: (context, snapshot) {
          bool isAdmin = snapshot.data ?? false;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepOrange),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 32,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Panneau d\'Administration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestion de l\'application',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                _buildMenuItem(
                  context,
                  'Tableau de bord',
                  Icons.dashboard,
                  () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                _buildMenuItem(
                  context,
                  'Gestion des Utilisateurs',
                  Icons.people,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementScreen(),
                    ),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Commentaires des Utilisateurs',
                  Icons.comment,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UsersCommentsScreen(),
                    ),
                  ),
                  // Ajoutez un badge pour montrer le nombre de messages non lus
                  badgeCount: _getBadgeCount(),
                ),
                _buildMenuItem(
                  context,
                  'Gestion des Capteurs',
                  Icons.sensors,
                  () {
                    // Navigation vers l'écran de gestion des capteurs
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  'Alertes & Notifications',
                  Icons.notifications_active,
                  () {
                    // Navigation vers l'écran des alertes
                    Navigator.pop(context);
                  },
                ),
                Divider(),
              ],
              _buildMenuItem(
                context,
                'Paramètres',
                Icons.settings,
                () => Navigator.pushNamed(context, '/settings'),
              ),
              _buildMenuItem(context, 'Se déconnecter', Icons.logout, () async {
                await _authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(title),
      trailing:
          badgeCount != null && badgeCount > 0
              ? Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
              : null,
      onTap: onTap,
    );
  }

  // Cette méthode sera remplacée par une vraie requête Firestore
  int _getBadgeCount() {
    // Retourner un nombre statique pour l'exemple
    // Dans une vraie application, vous feriez une requête pour compter les messages non lus
    return 5;
  }
}
