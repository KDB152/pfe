import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final String _collection = 'users';

  // Récupérer les détails d'un utilisateur par UID
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des détails utilisateur: $e');
      return null;
    }
  }

  Future<int> getUnreadCommentsCount() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('user_comments')
              .where('status', isEqualTo: 'non_lu')
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des messages non lus: $e');
      return 0;
    }
  }

  // Vérifier si un email existe dans la base Firestore
  Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_collection)
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }

  // Méthode pour soumettre un commentaire
  Future<void> submitComment(String subject, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    String userName = 'Utilisateur';
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['username'] ?? 'Utilisateur';
    }

    await _firestore.collection('user_comments').add({
      'userId': currentUser.uid,
      'userName': userName,
      'userEmail': currentUser.email,
      'subject': subject,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'non_lu',
    });
  }

  // Récupérer les détails d'un utilisateur par email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur par email: $e');
      return null;
    }
  }

  // Enregistrer un nouvel utilisateur
  Future<bool> saveUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'utilisateur: $e');
      return false;
    }
  }

  // Mettre à jour le statut d'un utilisateur
  Future<bool> updateUserStatus(
    String uid, {
    bool? isApproved,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (isApproved != null) updates['isApproved'] = isApproved;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore.collection(_collection).doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut utilisateur: $e');
      return false;
    }
  }

  // Récupérer tous les utilisateurs (pour l'admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // Supprimer un utilisateur
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      return false;
    }
  }

  // Méthode pour supprimer complètement un utilisateur (Auth + Firestore)
  Future<void> deleteUserCompletely(String userId) async {
    await _authService.deleteUser(userId);
  }

  // Méthode pour vérifier si l'utilisateur a été supprimé par un admin
  Future<bool> checkIfUserDeleted(String userId) async {
    try {
      DocumentSnapshot deletedDoc =
          await _firestore.collection('deleted_users').doc(userId).get();
      return deletedDoc.exists;
    } catch (e) {
      print('Erreur lors de la vérification du statut de suppression: $e');
      return false;
    }
  }
}
