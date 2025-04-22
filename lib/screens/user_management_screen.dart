import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _isLoading = true;
  String _filterValue = 'Tous';
  String _currentUserId = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkAdminStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';
    String username = '';
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Créer un nouvel utilisateur',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
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
                        const SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
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
                        const SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          style: const TextStyle(color: Colors.white),
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();

                                  try {
                                    var emailExists =
                                        await _firestore
                                            .collection('users')
                                            .where('email', isEqualTo: email)
                                            .get();

                                    if (emailExists.docs.isNotEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Un utilisateur avec cet email existe déjà',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    UserCredential userCredential = await _auth
                                        .createUserWithEmailAndPassword(
                                          email: email,
                                          password: password,
                                        );

                                    await _firestore
                                        .collection('users')
                                        .doc(userCredential.user!.uid)
                                        .set({
                                          'email': email,
                                          'username': username,
                                          'isAdmin': isAdmin,
                                          'isActive': true,
                                          'isApproved': true,
                                          'emailVerified': false,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'lastLogin': null,
                                        });

                                    await userCredential.user
                                        ?.sendEmailVerification();

                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Utilisateur créé avec succès. Vérifiez votre email.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } on FirebaseAuthException catch (e) {
                                    String errorMessage =
                                        'Une erreur est survenue';

                                    switch (e.code) {
                                      case 'email-already-in-use':
                                        errorMessage =
                                            'Cet email est déjà utilisé';
                                        break;
                                      case 'invalid-email':
                                        errorMessage =
                                            'Format d\'email invalide';
                                        break;
                                      case 'weak-password':
                                        errorMessage =
                                            'Le mot de passe est trop faible';
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
                                        content: Text(
                                          'Erreur lors de la création: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFD43C38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Créer',
                                style: TextStyle(fontFamily: 'Inter'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(String userIdToDelete, String username) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Confirmer la suppression',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Êtes-vous sûr de vouloir supprimer l\'utilisateur "$username" ?\n\nCette action supprimera définitivement le compte de Firebase Authentication et de Firestore.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Suppression du compte en cours...',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userIdToDelete).get();
        String email = userDoc['email'];

        await _firestore.collection('users').doc(userIdToDelete).delete();

        try {
          UserCredential userCredential = await _auth
              .signInWithEmailAndPassword(
                email: email,
                password: 'temporaryAdminPassword',
              );
          await userCredential.user!.delete();
        } catch (authError) {
          print(
            'Erreur lors de la suppression de l\'authentification: $authError',
          );
        }

        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Utilisateur supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
        SnackBar(content: const Text('Utilisateur approuvé avec succès')),
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

      if (isAdmin && isActive) {
        await _authService.signOut();
      }
    }
  }

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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Accès refusé',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous n\'avez pas les droits d\'administrateur',
                  style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pushReplacementNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD43C38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionnaire des Utilisateurs',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateUserDialog,
            tooltip: 'Créer un utilisateur',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _filterValue = value;
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Tous',
                    child: Text('Tous les utilisateurs'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Actifs',
                    child: Text('Utilisateurs actifs'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Inactifs',
                    child: Text('Utilisateurs inactifs'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'EnAttente',
                    child: Text('En attente d\'approbation'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Admins',
                    child: Text('Administrateurs'),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Erreur Firestore: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Une erreur est survenue',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Impossible de charger les utilisateurs',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            var users = snapshot.data!.docs;

            var filteredUsers =
                users.where((user) {
                  var userData = user.data() as Map<String, dynamic>;
                  var isActive = userData['isActive'] ?? true;
                  var isApproved = userData['isApproved'] ?? false;
                  var isAdmin = userData['isAdmin'] ?? false;

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
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun utilisateur trouvé',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Il n\'y a aucun utilisateur dans cette catégorie',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
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
                bool isCurrentUser = userId == _currentUserId;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isActive
                                    ? (isAdmin ? Colors.blue : Colors.green)
                                    : Colors.red,
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              if (isCurrentUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Vous',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: 'Inter',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isApproved && !isCurrentUser)
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
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
                                      () => _toggleUserActive(
                                        userId,
                                        isActive,
                                        isAdmin,
                                      ),
                                  tooltip: isActive ? 'Désactiver' : 'Activer',
                                ),
                              if (!isCurrentUser)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteUser(userId, username),
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
                                  Divider(color: Colors.white.withOpacity(0.3)),
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
                                        isApproved
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                  _buildInfoRow(
                                    'Compte',
                                    isActive ? 'Actif' : 'Désactivé',
                                    textColor:
                                        isActive ? Colors.green : Colors.red,
                                  ),
                                  _buildInfoRow(
                                    'Rôle',
                                    isAdmin ? 'Administrateur' : 'Utilisateur',
                                    textColor:
                                        isAdmin ? Colors.blue : Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!isCurrentUser && !isAdmin)
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  _setAdminStatus(userId, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            minimumSize: const Size(140, 45),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Promouvoir Admin',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      if (!isCurrentUser && isAdmin)
                                        ElevatedButton(
                                          onPressed:
                                              () => _setAdminStatus(
                                                userId,
                                                false,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.grey,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            minimumSize: const Size(140, 45),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Révoquer Admin',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      if (!isCurrentUser)
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  _deleteUser(userId, username),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            minimumSize: const Size(140, 45),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delete_forever,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Supprimer',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
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
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.white.withOpacity(0.8),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
