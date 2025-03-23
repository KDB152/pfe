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
      bool isAdminUser = email == 'detecteurincendie7@gmail.com';

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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user!.sendEmailVerification();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_username', username);
      await prefs.setString('pending_email', email);
      // Créer un document correspondant dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'email': email,
            'username': username,
            'isActive': true,
            'isApproved': false, // À approuver par un admin
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Créer le profil utilisateur dans Firestore après vérification de l'email
  Future<void> createUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('pending_username');
      await Firebase.initializeApp();

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Vérifier si c'est l'email initial d'admin
        bool isAdminUser = user.email == 'detecteurincendie7@gmail.com';

        await _firestore.collection('users').doc(user.uid).set({
          'username': username ?? user.displayName ?? 'User',
          'email': user.email,
          'isAdmin':
              isAdminUser, // Définir comme admin si c'est l'email initial
          'createdAt': Timestamp.now(),
          'emailVerified': user.emailVerified,
        });

        await prefs.remove('pending_username');
        await prefs.remove('pending_email');
      }
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
    } on FirebaseAuthException {
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
