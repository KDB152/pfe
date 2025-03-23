import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final bool isAdmin;

  AppDrawer({super.key, required this.isAdmin});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepOrange),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Icon(
                    Icons.local_fire_department,
                    size: 40,
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Détecteur Incendie',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Acceuil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers l'écran des notifications
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers l'écran des paramètres
            },
          ),
          // Section Admin uniquement
          if (isAdmin)
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Utilisateurs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/users_management');
              },
            ),
          // Section utilisateur normal uniquement
          if (!isAdmin)
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help');
              },
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
