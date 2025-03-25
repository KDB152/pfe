import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  bool _isAdmin = false;
  bool _isLoading = true;
  String _filterValue = 'Tous';
  String _currentUserId = '';
  bool _hasUserRated = false;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchAverageRating();
    _checkIfUserHasRated();
    _fetchAverageRating();
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

  Future<void> _fetchCurrentUserData() async {
    try {
      // Assuming you're using Firebase Authentication
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch the current user's document from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            _currentUserId = currentUser.uid;
            _isAdmin = userDoc.get('isAdmin') ?? false;
            _isLoading = false;
          });
        } else {
          // Handle case where user document doesn't exist
          setState(() {
            _isLoading = false;
          });
          print('User document not found');
        }
      } else {
        // No user is signed in
        setState(() {
          _isLoading = false;
        });
        // Optionally, redirect to login screen
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error fetching current user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAverageRating() async {
    try {
      var ratingSnapshot = await _firestore.collection('app_ratings').get();

      if (ratingSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        int ratingCount = ratingSnapshot.docs.length;

        for (var doc in ratingSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          _averageRating = totalRating / ratingCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _averageRating = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching average rating: $e');
      setState(() {
        _averageRating = 0.0;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfUserHasRated() async {
    try {
      var currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        var ratingDoc =
            await _firestore
                .collection('app_ratings')
                .where('userId', isEqualTo: currentUser.uid)
                .get();

        setState(() {
          _hasUserRated = ratingDoc.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking user rating: $e');
    }
  }

  Future<void> _rateApp(double rating) async {
    try {
      var currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        await _firestore.collection('app_ratings').add({
          'userId': currentUser.uid,
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _fetchAverageRating();

        setState(() {
          _hasUserRated = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Merci pour votre évaluation!')),
          );
        }
      }
    } catch (e) {
      print('Error rating app: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'évaluation')));
      }
    }
  }

  void _showRatingDialog() {
    double selectedRating = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Évaluer l\'application'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Donnez votre note pour cette application'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  Text('Note: ${selectedRating.toStringAsFixed(1)}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Envoyer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: () async {
                if (selectedRating > 0) {
                  try {
                    // Get current user ID
                    User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Veuillez vous connecter')),
                      );
                      return;
                    }

                    // Save rating to Firestore
                    await _firestore.collection('app_ratings').add({
                      'userId': currentUser.uid,
                      'rating': selectedRating,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // Update local state
                    setState(() {
                      _hasUserRated = true;
                    });

                    // Refetch average rating
                    await _fetchAverageRating();

                    // Close dialog
                    Navigator.of(context).pop();

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Merci pour votre évaluation !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Handle errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'envoi de la note'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // Prompt to select a rating
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez sélectionner une note'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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

  Future<void> _deleteUser(String userIdToDelete, String username) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'utilisateur "$username" ?\n\nCette action est irréversible et supprimera définitivement le compte.',
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

        // Utiliser la nouvelle méthode deleteUser
        await _authService.deleteUser(userIdToDelete);

        // Fermer le dialogue de chargement
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
        // Fermer le dialogue de chargement en cas d'erreur
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
    // Check if loading or not admin
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
    // Create a rating section widget
    Widget ratingSection = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Évaluation de l\'application',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _averageRating.toStringAsFixed(
                      1,
                    ), // Fixed the string interpolation
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 30),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _hasUserRated ? null : _showRatingDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: Text(
                  _hasUserRated ? 'Déjà évalué' : 'Évaluer l\'application',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionnaire des Utilisateurs'),
        backgroundColor: Colors.deepOrange,
        actions: [
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
      body: Column(
        children: [
          ratingSection,
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Aucun utilisateur trouvé'),
                        SizedBox(height: 8),
                        Text(
                          'Il n\'y a aucun utilisateur dans cette catégorie',
                        ),
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
                                icon: Icon(
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
                            // Ajouter le bouton de suppression
                            if (!isCurrentUser)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
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
                                  textColor:
                                      isActive ? Colors.green : Colors.red,
                                ),
                                _buildInfoRow(
                                  'Rôle',
                                  isAdmin ? 'Administrateur' : 'Utilisateur',
                                  textColor:
                                      isAdmin ? Colors.blue : Colors.black,
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
                                            () =>
                                                _setAdminStatus(userId, false),
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
                                            Icon(
                                              Icons.delete_forever,
                                              size: 18,
                                            ),
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
          ),
        ],
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
