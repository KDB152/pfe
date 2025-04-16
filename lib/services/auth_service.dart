import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Génère un code à 6 chiffres
  String _generateVerificationCode() {
    Random random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  Future<bool> isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    // Vérifier le statut admin dans Firestore plutôt que de comparer l'email
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['isAdmin'] == true;
    }

    if (user.email == 'detecteurincendie7@gmail.com') {
      // Vérifier si le document existe
      DocumentSnapshot docSnap =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnap.exists) {
        // Mettre à jour son statut comme admin si le document existe
        await _firestore.collection('users').doc(user.uid).update({
          'isAdmin': true,
        });
      } else {
        // Créer le document s'il n'existe pas encore
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } else {
      return false;
    }
  }

  // Créer un nouvel utilisateur
  Future<void> signUp(String email, String password, String username) async {
    try {
      // Créer l'utilisateur
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Vérifier si c'est l'email initial d'admin
      bool isAdminUser = (email == 'detecteurincendie7@gmail.com');

      // Ajouter les informations supplémentaires
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': username,
        'isAdmin': isAdminUser, // Définir comme admin si c'est l'email initial
        'isActive': true,
        'isApproved': isAdminUser, // Auto-approuvé si admin
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<User?> get user => _auth.authStateChanges();

  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  String getCurrentUserEmail() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user?.email ?? 'Email non disponible';
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Create user in Firebase Auth without adding to Firestore initially
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Générer un code de vérification à 6 chiffres
      String verificationCode = _generateVerificationCode();

      // Stocker le code dans Firestore
      await _firestore
          .collection('verification_codes')
          .doc(result.user!.uid)
          .set({
            'code': verificationCode,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(Duration(hours: 1)),
            ), // Expire après 1 heure
            'type': 'email_verification',
          });

      // Appeler une Cloud Function pour envoyer l'email avec le code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationEmail');
      await callable.call({
        'email': email,
        'code': verificationCode,
        'type': 'email_verification',
      });

      // Save temporary registration info in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_username', username);
      await prefs.setString('pending_email', email);
      await prefs.setString('pending_password', password);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier le code entré par l'utilisateur
  Future<bool> verifyEmailCode(String code) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot codeDoc =
          await _firestore.collection('verification_codes').doc(user.uid).get();

      if (!codeDoc.exists) return false;

      Map<String, dynamic> codeData = codeDoc.data() as Map<String, dynamic>;
      String storedCode = codeData['code'];
      Timestamp expiresAt = codeData['expiresAt'];

      // Vérifier si le code n'est pas expiré
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      // Vérifier que le code correspond
      if (code == storedCode) {
        // Marquer l'email comme vérifié dans Firebase Auth
        await user.updateEmailVerified(true);

        // Supprimer le code vérifié
        await _firestore
            .collection('verification_codes')
            .doc(user.uid)
            .delete();

        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification du code: $e');
      return false;
    }
  }

  // Modifié pour envoyer un code à 6 chiffres au lieu d'un lien
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      // Générer un nouveau code de vérification
      String verificationCode = _generateVerificationCode();

      // Stocker le code dans Firestore
      await _firestore.collection('verification_codes').doc(user.uid).set({
        'code': verificationCode,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        'type': 'email_verification',
      });

      // Appeler une Cloud Function pour envoyer l'email avec le code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationEmail');
      await callable.call({
        'email': user.email,
        'code': verificationCode,
        'type': 'email_verification',
      });
    }
  }

  // Modifier signInWithEmailAndPassword method
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!result.user!.emailVerified) {
        // Sign out and throw an exception to redirect to verification screen
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email not verified',
        );
      }

      // Only update Firestore if email is verified
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      print('E-mail et/ou mot de passe incorrect(s)');
      rethrow;
    }
  }

  // Modify createUserProfile to only create profile when email is verified
  Future<void> createUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('pending_username');
      String? email = prefs.getString('pending_email');

      await Firebase.initializeApp();

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Check if it's the initial admin email
        bool isAdminUser = user.email == 'detecteurincendie7@gmail.com';

        await _firestore.collection('users').doc(user.uid).set({
          'username': username ?? user.displayName ?? 'User',
          'email': email,
          'isAdmin': isAdminUser,
          'isActive': true,
          'isApproved': isAdminUser,
          'createdAt': Timestamp.now(),
          'emailVerified': user.emailVerified,
        });

        // Clear pending registration info
        await prefs.remove('pending_username');
        await prefs.remove('pending_email');
        await prefs.remove('pending_password');
      }
    }
  }

  Future<bool> isUserActive(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['isActive'] == true;
      }

      return true; // Par défaut, considérer le compte comme actif
    } catch (e) {
      print('Erreur lors de la vérification du statut du compte: $e');
      return true; // En cas d'erreur, permettre la connexion
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastLogin': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sauvegarder les identifiants (pour Remember Me)
  Future<void> saveCredentials(
    String email,
    String password,
    bool rememberMe,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }
      await prefs.setBool('remember_me', rememberMe);
    } catch (e) {
      print('Erreur lors de la sauvegarde des identifiants !!');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion !!');
      rethrow;
    }
  }

  // Dans auth_service.dart
  Future<void> resetPassword(String email) async {
    try {
      // Générer un code à 6 chiffres pour réinitialisation
      String verificationCode = _generateVerificationCode();

      // Stocker le code dans Firestore (utiliser l'email comme clé puisque nous n'avons pas d'UID)
      await _firestore.collection('password_reset_codes').doc(email).set({
        'code': verificationCode,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        'type': 'password_reset',
      });

      // Appeler une Cloud Function pour envoyer l'email avec le code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationEmail');
      await callable.call({
        'email': email,
        'code': verificationCode,
        'type': 'password_reset',
      });
    } on FirebaseAuthException {
      // Ne pas modifier l'exception, juste la propager
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier le code de réinitialisation de mot de passe
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    try {
      DocumentSnapshot codeDoc =
          await _firestore.collection('password_reset_codes').doc(email).get();

      if (!codeDoc.exists) return false;

      Map<String, dynamic> codeData = codeDoc.data() as Map<String, dynamic>;
      String storedCode = codeData['code'];
      Timestamp expiresAt = codeData['expiresAt'];

      // Vérifier si le code n'est pas expiré
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      // Vérifier que le code correspond
      return code == storedCode;
    } catch (e) {
      print('Erreur lors de la vérification du code: $e');
      return false;
    }
  }

  // Confirmer la réinitialisation du mot de passe après vérification du code
  Future<void> confirmPasswordReset(String email, String newPassword) async {
    try {
      // Utiliser la fonction de réinitialisation du mot de passe de Firebase
      await _auth.sendPasswordResetEmail(email: email);

      // Supprimer le code de réinitialisation
      await _firestore.collection('password_reset_codes').doc(email).delete();
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe: $e');
      rethrow;
    }
  }

  Future<void> deleteCurrentUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Aucun utilisateur connecté");
      await _setUserDeleted(user.uid);
      // Suppression directe si c'est l'utilisateur actuel
      await user.delete();
      if (user.email != null) {
        // Suppression par un admin via connexion temporaire
        await _deleteUserByAdmin(user.email!);
      }
    } catch (e) {
      print('Erreur lors de la suppression du compte: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Vérifier si l'utilisateur existe
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('Utilisateur non trouvé.');
        return;
      }
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Aucun utilisateur connecté");
      await _setUserDeleted(user.uid);
      // Suppression directe si c'est l'utilisateur actuel
      await user.delete();
      if (user.email != null) {
        // Suppression par un admin via connexion temporaire
        await _deleteUserByAdmin(user.email!);
      }
      // Mettre à jour "isDeleted" dans Firestore au lieu de supprimer l'utilisateur
      await _setUserDeleted(userId);
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      rethrow;
    }
  }

  // ✅ Méthode pour mettre "isDeleted" à true dans Firestore (sans supprimer l'utilisateur)
  Future<void> _setUserDeleted(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Fonction pour vérifier si un utilisateur est marqué comme supprimé
  Future<bool> isDeleted(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('isDeleted') ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de isDeleted: $e');
      return false;
    }
  }

  // 🔐 Suppression par un admin via connexion temporaire
  Future<void> _deleteUserByAdmin(String email) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'temporaryAdminPassword',
      );

      await userCredential.user?.delete();
    } catch (e) {
      print('Erreur lors de la suppression admin: $e');
      rethrow;
    }
  }

  // Supprimer les identifiants sauvegardés
  Future<void> clearSavedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    } catch (e) {
      print('Erreur lors de la suppression des identifiants !');
    }
  }

  // Vérifier si l'email est vérifié
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Changement d'email avec code de vérification
  Future<void> initiateEmailChange(String newEmail) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Générer un code de vérification
      String verificationCode = _generateVerificationCode();

      // Stocker le code et le nouvel email dans Firestore
      await _firestore.collection('verification_codes').doc(user.uid).set({
        'code': verificationCode,
        'currentEmail': user.email,
        'newEmail': newEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        'type': 'email_change',
      });

      // Envoyer l'email avec le code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationEmail');
      await callable.call({
        'email': newEmail, // Envoyer au nouvel email
        'code': verificationCode,
        'type': 'email_change',
      });
    }
  }

  // Vérifier le code pour le changement d'email
  Future<bool> verifyEmailChangeCode(String code) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot codeDoc =
          await _firestore.collection('verification_codes').doc(user.uid).get();

      if (!codeDoc.exists) return false;

      Map<String, dynamic> codeData = codeDoc.data() as Map<String, dynamic>;
      String storedCode = codeData['code'];
      Timestamp expiresAt = codeData['expiresAt'];
      String newEmail = codeData['newEmail'];

      // Vérifier si le code n'est pas expiré
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      // Vérifier que le code correspond
      if (code == storedCode) {
        // Mettre à jour l'email dans Firebase Auth
        await user.updateEmail(newEmail);

        // Mettre à jour l'email dans Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });

        // Supprimer le code vérifié
        await _firestore
            .collection('verification_codes')
            .doc(user.uid)
            .delete();

        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification du code: $e');
      return false;
    }
  }

  // Envoyer un code pour la suppression du compte
  Future<void> sendAccountDeletionVerificationCode() async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      // Générer un code de vérification
      String verificationCode = _generateVerificationCode();

      // Stocker le code dans Firestore
      await _firestore.collection('verification_codes').doc(user.uid).set({
        'code': verificationCode,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        'type': 'account_deletion',
      });

      // Envoyer l'email avec le code
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationEmail');
      await callable.call({
        'email': user.email,
        'code': verificationCode,
        'type': 'account_deletion',
      });
    }
  }

  // Vérifier le code pour la suppression du compte
  Future<bool> verifyAccountDeletionCode(String code) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot codeDoc =
          await _firestore.collection('verification_codes').doc(user.uid).get();

      if (!codeDoc.exists) return false;

      Map<String, dynamic> codeData = codeDoc.data() as Map<String, dynamic>;
      String storedCode = codeData['code'];
      Timestamp expiresAt = codeData['expiresAt'];

      // Vérifier si le code n'est pas expiré
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      // Vérifier que le code correspond
      if (code == storedCode) {
        // Supprimer le code vérifié
        await _firestore
            .collection('verification_codes')
            .doc(user.uid)
            .delete();

        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification du code: $e');
      return false;
    }
  }
}
