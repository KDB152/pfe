import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  int _rating = 0; // Default rating value

  @override
  void initState() {
    super.initState();
    print("HelpScreen initialized"); // Add this
    _loadUserInfo();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['username'] ?? 'Utilisateur';
          _userEmail = currentUser.email ?? '';
        });
      }
    }
  }

  // Ajoutez cette méthode dans la classe _HelpScreenState
  Widget _buildCommentHistory() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique de vos demandes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('user_comments')
                      .where('userId', isEqualTo: currentUser.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Vous n\'avez pas encore envoyé de demande'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return _buildConversationItem(data, doc.id);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> data, String docId) {
    String subject = data['subject'] ?? 'Sans sujet';
    String message = data['message'] ?? '';
    Timestamp? timestamp = data['timestamp'];
    String status = data['status'] ?? 'non_lu';
    String statusText =
        status == 'non_lu'
            ? 'Non lu'
            : (status == 'en_cours' ? 'En cours' : 'Résolu');
    String? adminResponse = data['adminResponse'];
    Timestamp? responseDate = data['responseDate'];

    Color statusColor;
    switch (status) {
      case 'non_lu':
        statusColor = Colors.red;
        break;
      case 'en_cours':
        statusColor = Colors.orange;
        break;
      case 'résolu':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text(subject, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${_formatDate(timestamp)} • ${statusText}',
          style: TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations supplémentaires
                Row(
                  children: [
                    Text(
                      'Email: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_userEmail),
                  ],
                ),
                SizedBox(height: 16),

                // Titre de conversation
                Text(
                  'Conversation:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Utiliser la méthode _buildConversationHistory ici
                _buildConversationHistory(data),

                // Statut et actions au bas
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
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
  }

  // Ajoutez cette méthode pour afficher l'historique des conversations
  Widget _buildConversationHistory(Map<String, dynamic> data) {
    if (!data.containsKey('conversations')) {
      // Si pas d'historique de conversation, utiliser le format initial
      var message = data['message'] ?? '';
      var adminResponse = data['adminResponse'];
      var responseDate = data['responseDate'] as Timestamp?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message initial de l'utilisateur
          _buildMessageBubble(
            message: message,
            timestamp: data['timestamp'] as Timestamp?,
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
      data['conversations'],
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

  // Ajoutez cette méthode de formatage de date
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH:mm').format(timestamp.toDate());
  }

  Future<void> _submitComment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance.collection('user_comments').add({
            'userId': currentUser.uid,
            'userName': _userName,
            'userEmail': _userEmail,
            'subject': _subjectController.text.trim(),
            'message': _messageController.text.trim(),
            'rating': _rating, // Save the rating to Firestore
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'non_lu', // Status: non_lu, en_cours, résolu
          });

          // Réinitialiser le formulaire
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _rating = 0; // Reset rating
          });

          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Votre commentaire a été envoyé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        // En cas d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'envoi du commentaire: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildCommentHistory(),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nous contacter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Si vous avez des questions ou rencontrez des problèmes, n\'hésitez pas à nous envoyer un message :',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _subjectController,
                        label: 'Sujet',
                        hint: 'Entrez le sujet de votre message',
                        prefixIcon: Icons.subject,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un sujet';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _messageController,
                        label: 'Message',
                        hint: 'Décrivez votre problème ou question en détail',
                        prefixIcon: Icons.message,
                        maxLines: 5, // Allow multiple lines for the message
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'ENVOYER',
                        isLoading: _isLoading,
                        onPressed: _submitComment,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations de contact (sans liens actifs)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations de contact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.email,
                        color: Colors.deepOrange,
                      ),
                      title: const Text('Email'),
                      subtitle: const Text('detecteurincendie7@gmail.com'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: Colors.deepOrange,
                      ),
                      title: const Text('Téléphone'),
                      subtitle: const Text('+216 22 900 603'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(padding: const EdgeInsets.all(16.0), child: Text(answer)),
      ],
    );
  }
}
