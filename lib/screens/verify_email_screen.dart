import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? action;
  final String? newEmail;
  final String? uid;
  final String? token;

  const VerifyEmailScreen({
    super.key,
    this.action,
    this.newEmail,
    this.uid,
    this.token,
  });

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class EmailVerificationSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Vérification réussie !',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Votre adresse email a été vérifiée avec succès.\n\nVous pouvez maintenant vous connecter à votre compte.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

                  // Naviguer vers un nouvel écran de succès
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailVerificationSuccessScreen(),
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

    setState(() {
      _isProcessing = true;
      _statusMessage = "Envoi de l'email de vérification en cours...";
      _errorMessage = ""; // Réinitialiser les messages d'erreur précédents
    });

    try {
      await _authService.sendVerificationEmail();

      setState(() {
        _canResendEmail = false;
        _resendTimeout = 60;
        _isProcessing = false;
        _statusMessage =
            "Un email de vérification a été envoyé à votre adresse email.";
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
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "";
        _errorMessage =
            "Erreur lors de l'envoi de l'email de vérification. Veuillez réessayer.";
      });
    }
  }

  Widget _buildActionIcon() {
    if (widget.action == 'email_change') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.email_outlined, size: 70, color: Colors.deepOrange),
      );
    } else if (widget.action == 'account_deletion') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.delete_forever, size: 70, color: Colors.red[700]),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mark_email_unread_rounded,
          size: 70,
          color: Colors.deepOrange,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildActionIcon(),
                  const SizedBox(height: 40),

                  if (_isProcessing)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  else if (_statusMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(fontSize: 17, color: Colors.blue[800]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (_isCreatingProfile)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Création de votre profil...',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  else if (_isEmailVerified)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Votre email a été vérifié!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (widget.action == null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Vérifiez votre adresse email',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nous avons envoyé un email de vérification à:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${FirebaseAuth.instance.currentUser?.email}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Veuillez vérifier votre boîte de réception et cliquer sur le lien de vérification.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  if (!_isEmailVerified &&
                      !_isCreatingProfile &&
                      widget.action == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _canResendEmail
                            ? 'Renvoyer l\'email de vérification'
                            : 'Renvoyer dans $_resendTimeout secondes',
                      ),
                      onPressed:
                          _canResendEmail ? _resendVerificationEmail : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (!_isCreatingProfile && !_isProcessing)
                    TextButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Retour à la connexion'),
                      onPressed: () {
                        if (widget.action == null) {
                          _timer.cancel();
                        }
                        _authService.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
