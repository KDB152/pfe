import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Send email verification
      await result.user!.sendEmailVerification();

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

  // Modify the signInWithEmailAndPassword method
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
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Ne pas modifier l'exception, juste la propager
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCurrentUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Aucun utilisateur connecté");

      // Supprimer d'abord les données Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Puis supprimer le compte Auth
      await user.delete();
    } catch (e) {
      print('Erreur lors de la suppression du compte: $e');
      rethrow;
    }
  }

  // Suppression d'un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      // 1. Supprimer le document utilisateur de Firestore
      await _firestore.collection('users').doc(userId).delete();
      // 2. Supprimer l'utilisateur de Firebase Authentication
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Si c'est l'utilisateur actuellement connecté
        await currentUser.delete();
      } else {
        // Si supprimé par un admin, récupérer l'utilisateur par son UID
        await _deleteUserFromAuth(userId);
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur: $e');
      rethrow;
    }
  } // Méthode privée pour supprimer un utilisateur de Firebase Auth

  Future<void> _deleteUserFromAuth(String userId) async {
    try {
      // Récupérer l'email de l'utilisateur depuis Firestore avant de le supprimer
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String? email = userDoc.get('email');
      if (email != null) {
        // Créer une méthode personnalisée pour supprimer l'utilisateur sans réauthentification directe
        await _adminDeleteUser(email);
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur d\'Auth: $e');
      rethrow;
    }
  }

  // Méthode pour la suppression par un admin
  Future<void> _adminDeleteUser(String email) async {
    try {
      // Récupérer tous les utilisateurs et trouver celui avec l'email correspondant
      UserCredential? userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: 'temporaryAdminPassword',
        // Un mot de passe temporaire sécurisé
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

  // Renvoyer l'email de vérification
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Nouvelle méthode pour vérifier l'email avant mise à jour
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(
        newEmail,
        ActionCodeSettings(
          url:
              'https://projet-fin-d-etudes-fe6a7.firebaseapp.com/update-email?email=$newEmail',
          handleCodeInApp: true,
          androidPackageName: 'com.projet-fin-d-etudes-fe6a7.package',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );

      // Mettre à jour l'email dans Firestore aussi
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
      });
    }
  }

  // Méthode pour vérifier l'email avant suppression du compte
  Future<void> sendAccountDeletionVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      await user.sendEmailVerification(
        ActionCodeSettings(
          url:
              'https://projet-fin-d-etudes-fe6a7.firebaseapp.com/delete-account?uid=${user.uid}',
          handleCodeInApp: true,
          androidPackageName: 'com.projet-fin-d-etudes-fe6a7.package',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );
    }
  }
}
