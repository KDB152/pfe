import 'package:fl_chart/fl_chart.dart';
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
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
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

  Future<void> _respondToComment(
    String commentId,
    String userEmail,
    String userName,
    String subject,
  ) async {
    _responseController.clear();

    try {
      // 1. Get user response from dialog
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Répondre à $userName'),
              content: TextField(
                controller: _responseController,
                decoration: InputDecoration(
                  hintText: 'Votre réponse...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(_responseController.text),
                  child: Text('Envoyer'),
                ),
              ],
            ),
      );

      if (result == null || result.trim().isEmpty) {
        return; // User cancelled or empty response
      }

      // 2. Update only minimal required fields first
      // This helps isolate which data field is causing the issue
      try {
        await _firestore.collection('user_comments').doc(commentId).update({
          'adminResponse': result,
          'responseDate': FieldValue.serverTimestamp(),
          'status': 'résolu',
        });

        print("Basic update successful");

        // 3. If that worked, try creating a notification (separate operation)
        try {
          String notificationId =
              _firestore.collection('user_notifications').doc().id;

          await _firestore
              .collection('user_notifications')
              .doc(notificationId)
              .set({
                'id': notificationId,
                'userEmail': userEmail,
                'title': 'Réponse à: $subject',
                'description': result,
                'timestamp': FieldValue.serverTimestamp(),
                'type': 'adminResponse',
                'isRead': false,
                'commentId': commentId,
              });

          print("Notification created successfully");
        } catch (notificationError) {
          print("Notification creation failed: $notificationError");
          // Continue even if notification fails
        }

        // 4. Only if previous steps worked, try updating the conversations field
        // This is likely where the error is occurring
        try {
          // Get current document after our initial update
          DocumentSnapshot commentDoc =
              await _firestore.collection('user_comments').doc(commentId).get();

          if (!commentDoc.exists) {
            throw Exception("Comment document not found");
          }

          // Create a simple conversations array with just two entries
          List<Map<String, dynamic>> conversations = [];

          // Add original message
          conversations.add({
            'sender': 'user',
            'message':
                (commentDoc.data() as Map<String, dynamic>)['message'] ?? '',
            'timestamp':
                (commentDoc.data() as Map<String, dynamic>)['timestamp'] ??
                Timestamp.now(),
          });

          // Add admin response
          conversations.add({
            'sender': 'admin',
            'message': result,
            'timestamp':
                Timestamp.now(), // Use current time instead of server timestamp
          });

          // Try to update just the conversations field
          await _firestore.collection('user_comments').doc(commentId).update({
            'conversations': conversations,
          });

          print("Conversations update successful");
        } catch (conversationsError) {
          print("Conversations update failed: $conversationsError");
          // Continue even if this update fails
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Réponse envoyée avec succès')),
          );
        }
      } catch (basicUpdateError) {
        print("Basic update failed: $basicUpdateError");
        throw basicUpdateError; // Re-throw for outer catch block
      }
    } catch (e) {
      print("Overall error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}',
            ),
          ),
        );
      }
    }
  }

  // Ajoutez cette méthode pour afficher l'historique des conversations
  Widget _buildConversationHistory(Map<String, dynamic> commentData) {
    if (!commentData.containsKey('conversations')) {
      // Si pas d'historique de conversation, utiliser le format initial (avant modification)
      var message = commentData['message'] ?? '';
      var adminResponse = commentData['adminResponse'];
      var responseDate = commentData['responseDate'] as Timestamp?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message initial de l'utilisateur
          _buildMessageBubble(
            message: message,
            timestamp: commentData['timestamp'] as Timestamp?,
            isAdmin: false,
          ),

          // Réponse de l'admin si elle existe
          if (adminResponse != null)
            _buildMessageBubble(
              message: adminResponse,
              timestamp: responseDate,
              isAdmin: true,
            ),
        ],
      );
    }

    // Sinon, afficher l'historique complet des conversations
    List<Map<String, dynamic>> conversations = List<Map<String, dynamic>>.from(
      commentData['conversations'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          conversations.map((conversation) {
            bool isAdmin = conversation['sender'] == 'admin';
            String message = conversation['message'] ?? '';
            Timestamp? timestamp;
            if (conversation['timestamp'] is Timestamp) {
              timestamp = conversation['timestamp'];
            }

            return _buildMessageBubble(
              message: message,
              timestamp: timestamp,
              isAdmin: isAdmin,
            );
          }).toList(),
    );
  }

  // Méthode helper pour créer une bulle de message
  Widget _buildMessageBubble({
    required String message,
    required Timestamp? timestamp,
    required bool isAdmin,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isAdmin ? 32 : 0,
        right: isAdmin ? 0 : 32,
      ),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isAdmin ? Colors.deepOrange.withOpacity(0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border:
            isAdmin
                ? Border.all(color: Colors.deepOrange.withOpacity(0.3))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdmin ? 'Admin' : 'Utilisateur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isAdmin ? Colors.deepOrange : Colors.black87,
                ),
              ),
              Text(
                _formatDate(timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(message),
        ],
      ),
    );
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
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterValue = value;
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'Tous', child: Text('Tous')),
                  PopupMenuItem(value: 'non_lu', child: Text('Non lus')),
                  PopupMenuItem(value: 'en_cours', child: Text('En cours')),
                  PopupMenuItem(value: 'résolu', child: Text('Résolus')),
                ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Filtre: $_filterValue'),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
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
              var adminResponse = commentData['adminResponse'];
              var responseDate = commentData['responseDate'] as Timestamp?;

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
                      if (adminResponse != null)
                        Text(
                          'Répondu',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            'Conversation:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          _buildConversationHistory(commentData),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Bouton de réponse
                              if (adminResponse == null)
                                OutlinedButton.icon(
                                  icon: Icon(Icons.reply),
                                  label: Text('Répondre'),
                                  onPressed:
                                      () => _respondToComment(
                                        commentId,
                                        userEmail,
                                        userName,
                                        subject,
                                      ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.deepOrange,
                                  ),
                                ),
                              SizedBox(width: 8),
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
                              SizedBox(width: 8),
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
