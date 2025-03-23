// lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _authService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });

    if (!isAdmin) {
      // Rediriger vers la page d'accueil si l'utilisateur n'est pas admin
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _approveUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isApproved': true,
    });
  }

  Future<void> _toggleUserActive(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': !isActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Gestion des Utilisateurs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              var userId = users[index].id;
              var isActive = userData['isActive'] ?? true;
              var isApproved = userData['isApproved'] ?? false;
              var email = userData['email'] ?? 'No email';
              var role = userData['role'] ?? 'user';

              // Ne pas afficher l'administrateur dans la liste
              if (email == 'mehdielabed86@gmail.com') {
                return SizedBox.shrink();
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(email),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rôle: $role'),
                      Row(
                        children: [
                          Text('Statut: '),
                          if (isApproved)
                            Text(
                              'Approuvé',
                              style: TextStyle(color: Colors.green),
                            )
                          else
                            Text(
                              'En attente',
                              style: TextStyle(color: Colors.orange),
                            ),
                          SizedBox(width: 10),
                          Text(
                            isActive ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isApproved)
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _approveUser(userId),
                          tooltip: 'Approuver',
                        ),
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleUserActive(userId, isActive),
                        tooltip: isActive ? 'Désactiver' : 'Activer',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
