import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../screens/home_screen.dart';

class UsersCommentsScreen extends StatefulWidget {
  const UsersCommentsScreen({Key? key}) : super(key: key);

  @override
  _UsersCommentsScreenState createState() => _UsersCommentsScreenState();
}

class _UsersCommentsScreenState extends State<UsersCommentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoading = true;
  String _filterValue = 'Tous';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _authService.isAdmin();

    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });

    if (!isAdmin && mounted) {
      // Rediriger vers la page d'accueil si l'utilisateur n'est pas admin
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Non disponible';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  Future<void> _updateCommentStatus(String commentId, String newStatus) async {
    await _firestore.collection('user_comments').doc(commentId).update({
      'status': newStatus,
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Statut mis à jour avec succès')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    // Afficher une boîte de dialogue de confirmation
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      await _firestore.collection('user_comments').doc(commentId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commentaire supprimé avec succès')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'non_lu':
        return Colors.red;
      case 'en_cours':
        return Colors.orange;
      case 'résolu':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
        title: Text('Commentaires des Utilisateurs'),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color.fromARGB(215, 255, 255, 255),
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          // Vos actions existantes
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Centrer horizontalement
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centrer verticalement
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.account_circle,
                      size: 50,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administrateur',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Gestion des utilisateurs'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/user-management');
              },
            ),
            ListTile(
              leading: Icon(Icons.comment),
              title: Text('Commentaires utilisateurs'),
              selected: true,
              selectedTileColor: Colors.orange.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Paramètres'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Aide & Support'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/help');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('user_comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Une erreur est survenue: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          var comments = snapshot.data!.docs;

          // Filtrer les commentaires selon le critère sélectionné
          var filteredComments =
              comments.where((comment) {
                var commentData = comment.data() as Map<String, dynamic>;
                var status = commentData['status'] ?? 'non_lu';

                if (_filterValue == 'Tous') {
                  return true;
                } else {
                  return status == _filterValue;
                }
              }).toList();

          if (filteredComments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun commentaire trouvé \n pour le moment',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredComments.length,
            itemBuilder: (context, index) {
              var commentData =
                  filteredComments[index].data() as Map<String, dynamic>;
              var commentId = filteredComments[index].id;
              var subject = commentData['subject'] ?? 'Sans sujet';
              var message = commentData['message'] ?? '';
              var userName = commentData['userName'] ?? 'Utilisateur inconnu';
              var userEmail = commentData['userEmail'] ?? 'Email inconnu';
              var timestamp = commentData['timestamp'] as Timestamp?;
              var status = commentData['status'] ?? 'non_lu';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    subject,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('De: $userName'),
                      Text('Date: ${_formatDate(timestamp)}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Row(
                            children: [
                              Text(
                                'Email: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(userEmail),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Message:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(message),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Status dropdown
                              DropdownButton<String>(
                                value: status,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _updateCommentStatus(commentId, newValue);
                                  }
                                },
                                items:
                                    <String>[
                                      'non_lu',
                                      'en_cours',
                                      'résolu',
                                    ].map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      String label;
                                      switch (value) {
                                        case 'non_lu':
                                          label = 'Non lu';
                                          break;
                                        case 'en_cours':
                                          label = 'En cours';
                                          break;
                                        case 'résolu':
                                          label = 'Résolu';
                                          break;
                                        default:
                                          label = value;
                                      }
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(label),
                                      );
                                    }).toList(),
                              ),
                              SizedBox(width: 16),
                              // Delete button
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteComment(commentId),
                                tooltip: 'Supprimer',
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
}
