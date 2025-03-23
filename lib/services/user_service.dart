import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
}
