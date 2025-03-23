import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc.exists &&
          doc.get('role') == 'admin' &&
          doc.get('email') == 'mehdielabed86@gmail.com';
    }
    return false;
  }

  // Créer un nouvel utilisateur
  Future<UserCredential> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Ajouter l'utilisateur à Firestore avec le rôle normal
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'role': 'user',
      'isApproved': false, // Nécessite approbation par admin
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  // État utilisateur actuel
  Stream<User?> get user => _auth.authStateChanges();

  // Vérifier si l'utilisateur est connecté
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Récupérer l'utilisateur actuel
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Inscription avec email et mot de passe
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Créer l'utilisateur avec Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Envoyer l'email de vérification
      await result.user!.sendEmailVerification();

      // Stocker les données temporairement - sans les enregistrer dans Firestore
      // On va les stocker dans SharedPreferences pour les récupérer plus tard
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_username', username);
      await prefs.setString('pending_email', email);

      return result;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  // Créer le profil utilisateur dans Firestore après vérification de l'email
  Future<void> createUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      // Récupérer les données temporaires
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('pending_username');
      await Firebase.initializeApp();

      // Vérifier si l'utilisateur existe déjà dans Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Créer le profil utilisateur
        await _firestore.collection('users').doc(user.uid).set({
          'username': username ?? user.displayName ?? 'User',
          'email': user.email,
          'createdAt': Timestamp.now(),
          'emailVerified': user.emailVerified,
        });

        // Nettoyer les données temporaires
        await prefs.remove('pending_username');
        await prefs.remove('pending_email');
      }
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('E-mail et/ou mot de passe incorrect(s)');
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
    } on FirebaseAuthException catch (e) {
      // Ne pas modifier l'exception, juste la propager
      rethrow;
    } catch (e) {
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
