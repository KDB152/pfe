import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  const AdminUsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersManagementScreen> createState() =>
      _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState
    extends State<AdminUsersManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();

      final List<UserModel> loadedUsers =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromMap({'uid': doc.id, ...data});
          }).toList();

      setState(() {
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des utilisateurs: $e')),
      );
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final username = user.username?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return username.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _toggleUserAdmin(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isAdmin': !user.isAdmin,
      });

      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = UserModel(
            uid: user.uid,
            username: user.username,
            email: user.email,
            isAdmin: !user.isAdmin,
            isApproved: user.isApproved,
            isActive: user.isActive,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isAdmin
                ? 'Privilèges administrateur retirés'
                : 'Privilèges administrateur attribués',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification des privilèges: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserApproval(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isApproved': !user.isApproved,
      });

      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = UserModel(
            uid: user.uid,
            username: user.username,
            email: user.email,
            isAdmin: user.isAdmin,
            isApproved: !user.isApproved,
            isActive: user.isActive,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isApproved
                ? 'Utilisateur désapprouvé'
                : 'Utilisateur approuvé',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification de l\'approbation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserActive(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isActive': !user.isActive,
      });

      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = UserModel(
            uid: user.uid,
            username: user.username,
            email: user.email,
            isAdmin: user.isAdmin,
            isApproved: user.isApproved,
            isActive: !user.isActive,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive ? 'Utilisateur désactivé' : 'Utilisateur activé',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification du statut: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    // Confirmer la suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer l\'utilisateur ${user.username ?? user.email}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Supprimer l'utilisateur de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Note: Pour une suppression complète, il faudrait également supprimer l'utilisateur de Firebase Auth
      // Cela nécessite généralement des fonctions Cloud pour des raisons de sécurité

      setState(() {
        _users.removeWhere((u) => u.uid == user.uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression de l\'utilisateur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      drawer: AppDrawer(isAdmin: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un utilisateur',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé'))
                    : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username ?? 'Sans nom',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'Pas d\'email',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'toggle_admin':
                        await _toggleUserAdmin(user);
                        break;
                      case 'toggle_approval':
                        await _toggleUserApproval(user);
                        break;
                      case 'toggle_active':
                        await _toggleUserActive(user);
                        break;
                      case 'delete':
                        await _deleteUser(user);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'toggle_admin',
                          child: Text(
                            user.isAdmin
                                ? 'Retirer les droits admin'
                                : 'Attribuer les droits admin',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_approval',
                          child: Text(
                            user.isApproved
                                ? 'Retirer l\'approbation'
                                : 'Approuver l\'utilisateur',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_active',
                          child: Text(
                            user.isActive
                                ? 'Désactiver le compte'
                                : 'Activer le compte',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Supprimer l\'utilisateur',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip(
                  label: 'Admin',
                  isActive: user.isAdmin,
                  color: Colors.purple,
                ),
                _buildStatusChip(
                  label: 'Approuvé',
                  isActive: user.isApproved,
                  color: Colors.green,
                ),
                _buildStatusChip(
                  label: 'Actif',
                  isActive: user.isActive,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isActive ? color : Colors.grey[300],
    );
  }
}
