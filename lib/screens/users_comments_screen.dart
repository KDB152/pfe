import 'dart:ui';
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

class _UsersCommentsScreenState extends State<UsersCommentsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoading = true;
  String _filterValue = 'Tous';
  final TextEditingController _responseController = TextEditingController();
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
    _responseController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    bool isAdmin = await _authService.isAdmin();

    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });

    if (!isAdmin && mounted) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Statut mis à jour avec succès')),
      );
    }
  }

  Future<void> _respondToComment(
    String commentId,
    String userEmail,
    String userName,
    String subject,
  ) async {
    String responseText = _responseController.text.trim();

    if (responseText.isEmpty) {
      return;
    }

    try {
      _responseController.clear();

      DocumentSnapshot commentDoc =
          await _firestore.collection('user_comments').doc(commentId).get();

      if (!commentDoc.exists) {
        throw Exception("Comment document not found");
      }

      Map<String, dynamic> commentData =
          commentDoc.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> conversations = [];

      if (commentData.containsKey('conversations') &&
          commentData['conversations'] is List) {
        conversations = List<Map<String, dynamic>>.from(
          commentData['conversations'],
        );
      } else {
        conversations.add({
          'sender': 'user',
          'message': commentData['message'] ?? '',
          'timestamp': commentData['timestamp'] ?? Timestamp.now(),
        });

        if (commentData.containsKey('adminResponse') &&
            commentData['adminResponse'] != null) {
          conversations.add({
            'sender': 'admin',
            'message': commentData['adminResponse'],
            'timestamp': commentData['responseDate'] ?? Timestamp.now(),
          });
        }
      }

      Timestamp currentTime = Timestamp.now();
      conversations.add({
        'sender': 'admin',
        'message': responseText,
        'timestamp': currentTime,
      });

      await _firestore.collection('user_comments').doc(commentId).update({
        'conversations': conversations,
        'adminResponse': responseText,
        'responseDate': currentTime,
        'status': 'en_cours',
      });

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
              'description': responseText,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'adminResponse',
              'isRead': false,
              'commentId': commentId,
            });
      } catch (notificationError) {
        print("Notification creation failed: $notificationError");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Réponse envoyée avec succès')),
        );
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

  Widget _buildConversationHistory(Map<String, dynamic> commentData) {
    if (!commentData.containsKey('conversations')) {
      var message = commentData['message'] ?? '';
      var adminResponse = commentData['adminResponse'];
      var responseDate = commentData['responseDate'] as Timestamp?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(
            message: message,
            timestamp: commentData['timestamp'] as Timestamp?,
            isAdmin: false,
          ),
          if (adminResponse != null)
            _buildMessageBubble(
              message: adminResponse,
              timestamp: responseDate,
              isAdmin: true,
            ),
        ],
      );
    }

    List<Map<String, dynamic>> conversations = List<Map<String, dynamic>>.from(
      commentData['conversations'],
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
                        color: isAdmin ? Colors.white : Colors.white,
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

  Future<void> _deleteComment(String commentId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => Dialog(
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
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
                          const Text(
                            'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                            style: TextStyle(
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
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(
                                    color: Colors.red,
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
              ),
        ) ??
        false;

    if (confirm) {
      await _firestore.collection('user_comments').doc(commentId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Commentaire supprimé avec succès')),
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
          'Commentaires des Utilisateurs',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterValue = value;
              });
            },
            icon: const Icon(Icons.filter_list, color: Colors.white),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'Tous', child: Text('Tous')),
                  const PopupMenuItem(value: 'non_lu', child: Text('Non lus')),
                  const PopupMenuItem(
                    value: 'en_cours',
                    child: Text('En cours'),
                  ),
                  const PopupMenuItem(value: 'résolu', child: Text('Résolus')),
                ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          radius: 30,
                          child: const Icon(
                            Icons.account_circle,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Administrateur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text(
                      'Accueil',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.white),
                    title: const Text(
                      'Gestion des utilisateurs',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/user-management',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.comment, color: Colors.white),
                    title: const Text(
                      'Commentaires utilisateurs',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    selected: true,
                    selectedTileColor: Colors.white.withOpacity(0.2),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      'Paramètres',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.white),
                    title: const Text(
                      'Aide & Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/help');
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('user_comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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

            var comments = snapshot.data!.docs;

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
                    const Icon(
                      Icons.message_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun commentaire trouvé \n pour le moment',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredComments.length,
              itemBuilder: (context, index) {
                var commentData =
                    filteredComments[index].data() as Map<String, dynamic>;
                var commentId = filteredComments[index].id;
                var subject = commentData['subject'] ?? 'Sans sujet';
                var userName = commentData['userName'] ?? 'Utilisateur inconnu';
                var userEmail = commentData['userEmail'] ?? 'Email inconnu';
                var timestamp = commentData['timestamp'] as Timestamp?;
                var status = commentData['status'] ?? 'non_lu';
                var adminResponse = commentData['adminResponse'];

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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'De: $userName',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                'Date: ${_formatDate(timestamp)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (adminResponse != null)
                                Text(
                                  'Répondu',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(color: Colors.white.withOpacity(0.3)),
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
                                        userEmail,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Conversation:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildConversationHistory(commentData),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _responseController,
                                                decoration: InputDecoration(
                                                  hintText: 'Votre réponse...',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontFamily: 'Inter',
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.send,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                if (_responseController.text
                                                    .trim()
                                                    .isNotEmpty) {
                                                  _respondToComment(
                                                    commentId,
                                                    userEmail,
                                                    userName,
                                                    subject,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      DropdownButton<String>(
                                        value: status,
                                        dropdownColor: Colors.black.withOpacity(
                                          0.9,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white,
                                        ),
                                        underline: Container(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            _updateCommentStatus(
                                              commentId,
                                              newValue,
                                            );
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
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteComment(commentId),
                                        tooltip: 'Supprimer',
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
}
