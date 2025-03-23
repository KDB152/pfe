// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String userEmail;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AdminSidebar({
    Key? key,
    required this.userEmail,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepOrange),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.deepOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Accueil'),
            selected: selectedIndex == 0,
            onTap: () {
              onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Gestion Utilisateurs'),
            selected: selectedIndex == 1,
            onTap: () {
              onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            selected: selectedIndex == 2,
            onTap: () {
              onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
            selected: selectedIndex == 3,
            onTap: () {
              onItemTapped(3);
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () async {
              await Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
