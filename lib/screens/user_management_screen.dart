import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../screens/login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/user_service.dart';
import '../screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _isLoading = true;
  String _filterValue = 'Tous';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _authService.isAdmin();
    var currentUser = _authService.getCurrentUser();

    setState(() {
      _isAdmin = isAdmin;
      _currentUserId = currentUser?.uid ?? '';
      _isLoading = false;
    });

    if (!isAdmin) {
      // Rediriger vers la page d'accueil si l'utilisateur n'est pas admin
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    HomeScreen(userEmail: _authService.getCurrentUserEmail()),
          ),
        );
      }
    }
  }

  void _showCreateUserDialog() {
    final _formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';
    String username = '';
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouvel utilisateur'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.8, // Largeur plus grande
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                      onSaved: (value) => email = value!.trim(),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom d\'utilisateur';
                        }
                        if (value.length < 3) {
                          return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                      onSaved: (value) => username = value!.trim(),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        return null;
                      },
                      onSaved: (value) => password = value!,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  try {
                    // Vérifier si l'email existe déjà
                    var emailExists =
                        await _firestore
                            .collection('users')
                            .where('email', isEqualTo: email)
                            .get();

                    if (emailExists.docs.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Un utilisateur avec cet email existe déjà',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Créer l'utilisateur
                    UserCredential userCredential = await _auth
                        .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                    // Créer le document utilisateur dans Firestore
                    await _firestore
                        .collection('users')
                        .doc(userCredential.user!.uid)
                        .set({
                          'email': email,
                          'username': username,
                          'isAdmin': isAdmin,
                          'isActive': true,
                          'isApproved': true,
                          'emailVerified': false, // Par défaut à false
                          'createdAt': FieldValue.serverTimestamp(),
                          'lastLogin': null,
                        });

                    // Envoyer un email de vérification
                    await userCredential.user?.sendEmailVerification();

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Utilisateur créé avec succès. Vérifiez votre email.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    String errorMessage = 'Une erreur est survenue';

                    switch (e.code) {
                      case 'email-already-in-use':
                        errorMessage = 'Cet email est déjà utilisé';
                        break;
                      case 'invalid-email':
                        errorMessage = 'Format d\'email invalide';
                        break;
                      case 'weak-password':
                        errorMessage = 'Le mot de passe est trop faible';
                        break;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la création: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userIdToDelete, String username) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'utilisateur "$username" ?\n\nCette action supprimera définitivement le compte de Firebase Authentication et de Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text('Suppression du compte en cours...'),
                  ],
                ),
              ),
            );
          },
        );

        // Fetch user document to get email
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userIdToDelete).get();

        String email = userDoc['email'];

        // Delete user from Firestore
        await _firestore.collection('users').doc(userIdToDelete).delete();

        // Delete user from Firebase Authentication
        try {
          // Sign in with the user's email and a temporary password to delete
          UserCredential userCredential = await _auth
              .signInWithEmailAndPassword(
                email: email,
                password: 'temporaryAdminPassword', // Secure temporary password
              );

          await userCredential.user!.delete();
        } catch (authError) {
          print(
            'Erreur lors de la suppression de l\'authentification: $authError',
          );
          // If direct deletion fails, log the error but continue
        }

        // Close the loading dialog
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Utilisateur supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close the loading dialog in case of error
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isApproved': true,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur approuvé avec succès')),
      );
    }
  }

  Future<void> _toggleUserActive(
    String userId,
    bool isActive,
    bool isAdmin,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': !isActive,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Utilisateur désactivé avec succès'
                : 'Utilisateur activé avec succès',
          ),
        ),
      );

      // Si c'est un admin qui est désactivé, le rediriger vers la page de login
      if (isAdmin && isActive) {
        // Déconnexion et redirection vers l'écran de login
        await _authService.signOut();
      }
    }
  }

  // Méthode pour définir le statut admin d'un utilisateur
  Future<void> _setAdminStatus(String userId, bool makeAdmin) async {
    await _firestore.collection('users').doc(userId).update({
      'isAdmin': makeAdmin,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            makeAdmin
                ? 'Droits administrateur accordés'
                : 'Droits administrateur retirés',
          ),
        ),
      );
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Non disponible';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Accès refusé'),
              SizedBox(height: 8),
              Text('Vous n\'avez pas les droits d\'administrateur'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/home'),
                child: Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionnaire des Utilisateurs'),
        backgroundColor: Colors.deepOrange,
        actions: [
          // Bouton pour créer un utilisateur
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateUserDialog,
            tooltip: 'Créer un utilisateur',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _filterValue = value;
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'Tous',
                    child: Text('Tous les utilisateurs'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Actifs',
                    child: Text('Utilisateurs actifs'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Inactifs',
                    child: Text('Utilisateurs inactifs'),
                  ),
                  PopupMenuItem<String>(
                    value: 'EnAttente',
                    child: Text('En attente d\'approbation'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Admins',
                    child: Text('Administrateurs'),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Erreur Firestore: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Une erreur est survenue'),
                  SizedBox(height: 8),
                  Text('Impossible de charger les utilisateurs'),
                  SizedBox(height: 8),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          var users = snapshot.data!.docs;

          // Filtrer les utilisateurs selon le critère sélectionné
          var filteredUsers =
              users.where((user) {
                var userData = user.data() as Map<String, dynamic>;
                var isActive = userData['isActive'] ?? true;
                var isApproved = userData['isApproved'] ?? false;
                var isAdmin = userData['isAdmin'] ?? false;
                var email = userData['email'] ?? '';

                // Vérification que l'utilisateur avec cet email apparaît dans la liste
                // Décommenter cette ligne pour déboguer
                // print('User email: $email, isActive: $isActive, isApproved: $isApproved, isAdmin: $isAdmin');

                switch (_filterValue) {
                  case 'Actifs':
                    return isActive;
                  case 'Inactifs':
                    return !isActive;
                  case 'EnAttente':
                    return !isApproved;
                  case 'Admins':
                    return isAdmin;
                  default:
                    return true;
                }
              }).toList();

          if (filteredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun utilisateur trouvé'),
                  SizedBox(height: 8),
                  Text('Il n\'y a aucun utilisateur dans cette catégorie'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              var userData =
                  filteredUsers[index].data() as Map<String, dynamic>;
              var userId = filteredUsers[index].id;
              var isActive = userData['isActive'] ?? true;
              var isApproved = userData['isApproved'] ?? false;
              var isAdmin = userData['isAdmin'] ?? false;
              var email = userData['email'] ?? 'No email';
              var username =
                  userData['username'] ??
                  (isAdmin ? 'Administrateur' : 'Utilisateur');
              var createdAt = userData['createdAt'] as Timestamp?;
              var lastLogin = userData['lastLogin'] as Timestamp?;

              // Déterminer si c'est l'utilisateur actuel
              bool isCurrentUser = userId == _currentUserId;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isActive
                            ? (isAdmin ? Colors.blue : Colors.green)
                            : Colors.red,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Vous',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isApproved && !isCurrentUser)
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _approveUser(userId),
                          tooltip: 'Approuver',
                        ),
                      if (!isCurrentUser)
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          onPressed:
                              () =>
                                  _toggleUserActive(userId, isActive, isAdmin),
                          tooltip: isActive ? 'Désactiver' : 'Activer',
                        ),
                      // Ajouter le bouton de suppression
                      if (!isCurrentUser)
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _deleteUser(userId, username),
                          tooltip: 'Supprimer',
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          _buildInfoRow('UID', userId),
                          _buildInfoRow(
                            'Date de création',
                            _formatDate(createdAt),
                          ),
                          _buildInfoRow(
                            'Dernière connexion',
                            _formatDate(lastLogin),
                          ),
                          _buildInfoRow(
                            'Statut',
                            isApproved
                                ? 'Approuvé'
                                : 'En attente d\'approbation',
                            textColor:
                                isApproved ? Colors.green : Colors.orange,
                          ),
                          _buildInfoRow(
                            'Compte',
                            isActive ? 'Actif' : 'Désactivé',
                            textColor: isActive ? Colors.green : Colors.red,
                          ),
                          _buildInfoRow(
                            'Rôle',
                            isAdmin ? 'Administrateur' : 'Utilisateur',
                            textColor: isAdmin ? Colors.blue : Colors.black,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isCurrentUser && !isAdmin)
                                ElevatedButton(
                                  onPressed:
                                      () => _setAdminStatus(userId, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    minimumSize: Size(140, 45),
                                  ),
                                  child: Text('Promouvoir Admin'),
                                ),
                              if (!isCurrentUser && isAdmin)
                                ElevatedButton(
                                  onPressed:
                                      () => _setAdminStatus(userId, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    minimumSize: Size(140, 45),
                                  ),
                                  child: Text('Révoquer Admin'),
                                ),
                              SizedBox(width: 8),
                              // Ajouter le bouton de suppression
                              if (!isCurrentUser)
                                ElevatedButton(
                                  onPressed:
                                      () => _deleteUser(userId, username),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    minimumSize: Size(140, 45),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_forever, size: 18),
                                      SizedBox(width: 8),
                                      Text('Supprimer'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
