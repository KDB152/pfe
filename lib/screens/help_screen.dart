import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _replyController = TextEditingController();
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  int _rating = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("HelpScreen initialized");
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadUserInfo();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _replyController.dispose();
    _animationController.dispose();
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

  Widget _buildCommentHistory() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique de vos demandes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
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
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Vous n\'avez pas encore envoyé de demande',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> data, String docId) {
    String subject = data['subject'] ?? 'Sans sujet';
    Timestamp? timestamp = data['timestamp'];
    String status = data['status'] ?? 'non_lu';
    String statusText =
        status == 'non_lu'
            ? 'Non lu'
            : (status == 'en_cours' ? 'En cours' : 'Résolu');
    String? adminResponse = data['adminResponse'];

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ExpansionTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              subtitle: Text(
                '${_formatDate(timestamp)} • $statusText',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Inter',
                ),
              ),
              initiallyExpanded:
                  timestamp != null &&
                  timestamp.toDate().isAfter(
                    DateTime.now().subtract(const Duration(minutes: 5)),
                  ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Email: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            _userEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Conversation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildConversationHistoryView(data),
                      if (status == 'résolu' ||
                          adminResponse != null ||
                          status == 'en_cours')
                        const SizedBox(height: 16),
                      if (status != 'non_lu') _buildReplySection(docId),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
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
  }

  Widget _buildReplySection(String docId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajouter un message:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _replyController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: 'Votre réponse...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Inter',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendReply(docId),
                  ),
                ),
                maxLines: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendReply(String docId) async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un message')),
      );
      return;
    }

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('user_comments')
              .doc(docId)
              .get();

      if (!doc.exists) {
        throw Exception("Document introuvable");
      }

      var data = doc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> conversations = [];

      if (data.containsKey('conversations') && data['conversations'] is List) {
        conversations = List<Map<String, dynamic>>.from(data['conversations']);
      } else {
        conversations.add({
          'sender': 'user',
          'message': data['message'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        });

        if (data.containsKey('adminResponse') &&
            data['adminResponse'] != null) {
          conversations.add({
            'sender': 'admin',
            'message': data['adminResponse'],
            'timestamp': data['responseDate'] ?? Timestamp.now(),
          });
        }
      }

      conversations.add({
        'sender': 'user',
        'message': _replyController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('user_comments')
          .doc(docId)
          .update({'conversations': conversations, 'status': 'en_cours'});

      _replyController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé avec succès')),
      );
    } catch (e) {
      print("Erreur lors de l'envoi de la réponse: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'envoi: $e')));
    }
  }

  Widget _buildConversationHistoryView(Map<String, dynamic> data) {
    if (!data.containsKey('conversations') ||
        !(data['conversations'] is List) ||
        (data['conversations'] as List).isEmpty) {
      var message = data['message'] ?? '';
      var adminResponse = data['adminResponse'];
      var responseDate = data['responseDate'] as Timestamp?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(
            message: message,
            timestamp: data['timestamp'] as Timestamp?,
            isAdmin: false,
          ),
          if (adminResponse != null && adminResponse.isNotEmpty)
            _buildMessageBubble(
              message: adminResponse,
              timestamp: responseDate,
              isAdmin: true,
            ),
        ],
      );
    }

    List<Map<String, dynamic>> conversations = List<Map<String, dynamic>>.from(
      data['conversations'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          conversations.asMap().entries.map((entry) {
            int index = entry.key;
            var conversation = entry.value;
            bool isAdmin = conversation['sender'] == 'admin';
            String message = conversation['message'] ?? '';
            Timestamp? timestamp =
                conversation['timestamp'] is Timestamp
                    ? conversation['timestamp']
                    : null;

            return AnimatedOpacity(
              opacity: _fadeAnimation.value,
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildMessageBubble(
                message: message,
                timestamp: timestamp,
                isAdmin: isAdmin,
              ),
            );
          }).toList(),
    );
  }

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isAdmin ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      _formatDate(timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
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
  }

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
          List<Map<String, dynamic>> conversations = [
            {
              'sender': 'user',
              'message': _messageController.text.trim(),
              'timestamp': Timestamp.now(),
            },
          ];

          Timestamp currentTimestamp = Timestamp.now();

          await FirebaseFirestore.instance.collection('user_comments').add({
            'userId': currentUser.uid,
            'userName': _userName,
            'userEmail': _userEmail,
            'subject': _subjectController.text.trim(),
            'message': _messageController.text.trim(),
            'rating': _rating,
            'timestamp': currentTimestamp,
            'status': 'non_lu',
            'conversations': conversations,
          });

          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _rating = 0;
          });

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
        title: const Text(
          'Aide & Support',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildCommentHistory(),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
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
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Si vous avez des questions ou rencontrez des problèmes, n\'hésitez pas à nous envoyer un message :',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Sujet',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Inter',
                                ),
                                hintText: 'Entrez le sujet de votre message',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontFamily: 'Inter',
                                ),
                                prefixIcon: const Icon(
                                  Icons.subject,
                                  color: Colors.white,
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
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un sujet';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Message',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Inter',
                                ),
                                hintText:
                                    'Décrivez votre problème ou question en détail',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontFamily: 'Inter',
                                ),
                                prefixIcon: const Icon(
                                  Icons.message,
                                  color: Colors.white,
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
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre message';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submitComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFD43C38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Color(0xFFD43C38),
                                      )
                                      : const Text(
                                        'ENVOYER',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFFD43C38),
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations de contact',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                            subtitle: const Text(
                              'detecteurincendie7@gmail.com',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          Divider(color: Colors.white.withOpacity(0.3)),
                          ListTile(
                            leading: const Icon(
                              Icons.phone,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Téléphone',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                            subtitle: const Text(
                              '+216 22 900 603',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
