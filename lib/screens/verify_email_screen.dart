import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? action;
  final String? newEmail;
  final String? uid;
  final String? token;

  const VerifyEmailScreen({
    Key? key,
    this.action,
    this.newEmail,
    this.uid,
    this.token,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  late Timer _timer;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _resendTimeout = 0;
  late Timer _resendTimer;
  bool _isCreatingProfile = false;
  bool _isProcessing = false;
  String _errorMessage = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();

    // Vérifier si nous sommes dans un processus de changement d'email ou de suppression de compte
    if (widget.action == 'email_change' && widget.newEmail != null) {
      _processEmailChange();
    } else if (widget.action == 'account_deletion') {
      _processAccountDeletion();
    } else {
      // Vérifier l'état initial pour la vérification d'email standard
      _isEmailVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (!_isEmailVerified) {
        // Vérifier périodiquement si l'email est vérifié
        _timer = Timer.periodic(Duration(seconds: 3), (_) async {
          try {
            await FirebaseAuth.instance.currentUser?.reload();
            final bool newEmailVerified =
                FirebaseAuth.instance.currentUser?.emailVerified ?? false;

            if (newEmailVerified && !_isEmailVerified) {
              _timer.cancel();

              if (mounted) {
                setState(() {
                  _isEmailVerified = true;
                  _isCreatingProfile = true;
                });

                try {
                  // Créer le profil utilisateur maintenant que l'email est vérifié
                  await _authService.createUserProfile();

                  // Rediriger vers la page d'accueil
                  var userEmail = FirebaseAuth.instance.currentUser?.email;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(userEmail: userEmail!),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _errorMessage =
                          "Votre compte a été créé avec succès ! Vous pouvez maintenant vous connecter.";
                      _isCreatingProfile = false;
                    });
                  }
                }
              }
            }
          } catch (e) {
            print("Erreur lors de la vérification de l'email !!");
          }
        });
      }
    }
  }

  // Méthode pour traiter le changement d'email
  Future<void> _processEmailChange() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Traitement du changement d'email en cours...";
    });

    try {
      // Envoyer l'email de vérification à la nouvelle adresse
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendVerificationToNewEmail');

      final result = await callable.call({
        'newEmail': widget.newEmail,
        'uid': widget.uid,
        'token': widget.token,
      });

      if (result.data['success'] == true) {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              "Un email de vérification a été envoyé à votre nouvelle adresse ${widget.newEmail}. Veuillez vérifier votre boîte de réception et cliquer sur le lien pour finaliser le changement.";
        });
      } else {
        throw Exception(result.data['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Erreur lors du traitement du changement d'email !!";
      });
    }
  }

  // Méthode pour traiter la suppression du compte
  Future<void> _processAccountDeletion() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Traitement de la suppression du compte en cours...";
    });

    try {
      // Vérifier le code OOB et supprimer le compte via la Cloud Function
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('processAccountDeletion');

      final result = await callable.call({
        'uid': widget.uid,
        'oobCode': widget.token,
      });

      if (result.data['success'] == true) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Votre compte a été supprimé avec succès.";
        });

        // Rediriger vers la page de connexion après un court délai
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else {
        throw Exception(result.data['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage =
            "Erreur lors de la suppression du compte : ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    if (!_isEmailVerified && widget.action == null) {
      _timer.cancel();
    }
    if (_resendTimeout > 0) {
      _resendTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      await _authService.sendVerificationEmail();

      setState(() {
        _canResendEmail = false;
        _resendTimeout = 60;
      });

      _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_resendTimeout > 0) {
            _resendTimeout--;
          } else {
            _canResendEmail = true;
            timer.cancel();
          }
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Un email de vérification a été envoyé à votre adresse email.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de l\'email de vérification.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Vérification de l\'email';
    if (widget.action == 'email_change') {
      title = 'Changement d\'email';
    } else if (widget.action == 'account_deletion') {
      title = 'Suppression du compte';
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.deepOrange),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.action == 'email_change')
                Icon(Icons.email_outlined, size: 80, color: Colors.deepOrange)
              else if (widget.action == 'account_deletion')
                Icon(Icons.delete_forever, size: 80, color: Colors.deepOrange)
              else
                Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Colors.deepOrange,
                ),

              SizedBox(height: 32),

              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                )
              else if (_isCreatingProfile)
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text(
                      'Création de votre profil...',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else if (_isEmailVerified)
                Text(
                  'Votre email a été vérifié!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (widget.action == null)
                Column(
                  children: [
                    Text(
                      'Vérifiez votre adresse email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nous avons envoyé un email de vérification à l\'adresse ${FirebaseAuth.instance.currentUser?.email}. Veuillez vérifier votre boîte de réception et cliquer sur le lien de vérification.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: 32),

              if (!_isEmailVerified &&
                  !_isCreatingProfile &&
                  widget.action == null)
                ElevatedButton(
                  onPressed: _canResendEmail ? _resendVerificationEmail : null,
                  child: Text(
                    _canResendEmail
                        ? 'Renvoyer l\'email de vérification'
                        : 'Renvoyer dans $_resendTimeout secondes',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),

              SizedBox(height: 16),

              if (!_isCreatingProfile && !_isProcessing)
                TextButton(
                  onPressed: () {
                    if (widget.action == null) {
                      _timer.cancel();
                    }
                    _authService.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                    child: Text('Retour à la connexion'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
