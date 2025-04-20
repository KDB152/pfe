import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Vérification réussie !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Votre adresse email a été vérifiée avec succès.\n\nVous pouvez maintenant vous connecter à votre compte.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                            fontFamily: 'Inter',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'Se connecter',
                    isLoading: false,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    textColor: Colors.white,
                    gradient: LinearGradient(
                      colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                    ),
                    borderRadius: 12,
                    textSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    elevation: 0,
                    shadowColor: Color(0xFFD43C38).withOpacity(0.4),
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

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _resendTimer = Timer(Duration.zero, () {});

    if (widget.action == 'email_change' && widget.newEmail != null) {
      _processEmailChange();
    } else if (widget.action == 'account_deletion') {
      _processAccountDeletion();
    } else {
      _isEmailVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (!_isEmailVerified) {
        _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
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
                  await _authService.createUserProfile();
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
                    _clearMessagesAfterDelay();
                  }
                }
              }
            }
          } catch (e) {
            print("Erreur lors de la vérification de l'email : $e");
          }
        });
      }
    }
  }

  void _clearMessagesAfterDelay() {
    Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
          _errorMessage = '';
        });
      }
    });
  }

  Future<void> _processEmailChange() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Traitement du changement d'email en cours...";
    });

    try {
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
        _clearMessagesAfterDelay();
      } else {
        throw Exception(result.data['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Erreur lors du changement d'email : ${e.toString()}";
      });
      _clearMessagesAfterDelay();
    }
  }

  Future<void> _processAccountDeletion() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Traitement de la suppression du compte en cours...";
    });

    try {
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

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }
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
      _clearMessagesAfterDelay();
    }
  }

  @override
  void dispose() {
    if (!_isEmailVerified && widget.action == null) {
      _timer.cancel();
    }
    _resendTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Envoi de l'email de vérification en cours...";
      _errorMessage = "";
    });

    try {
      await _authService.sendVerificationEmail();

      setState(() {
        _canResendEmail = false;
        _resendTimeout = 60; // 60-second cooldown
        _isProcessing = false;
        _statusMessage =
            "Un email de vérification a été envoyé à votre adresse email.";
      });
      _clearMessagesAfterDelay();

      _resendTimer.cancel();
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
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'too-many-requests') {
        errorMessage = "Veuillez réessayer dans une minute !";
      } else {
        errorMessage =
            "Erreur lors de l'envoi de l'email de vérification : ${e.message}";
      }
      setState(() {
        _isProcessing = false;
        _statusMessage = "";
        _errorMessage = errorMessage;
      });
      _clearMessagesAfterDelay();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "";
        _errorMessage =
            "Erreur lors de l'envoi de l'email de vérification : ${e.toString()}";
      });
      _clearMessagesAfterDelay();
    }
  }

  Widget _buildActionIcon() {
    IconData icon;
    Color iconColor;
    Color backgroundColor;

    if (widget.action == 'email_change') {
      icon = Icons.email_outlined;
      iconColor = Colors.white;
      backgroundColor = Colors.white.withOpacity(0.1);
    } else if (widget.action == 'account_deletion') {
      icon = Icons.delete_forever;
      iconColor = Colors.white;
      backgroundColor = Colors.white.withOpacity(0.1);
    } else {
      icon = Icons.mark_email_unread_rounded;
      iconColor = Colors.white;
      backgroundColor = Colors.white.withOpacity(0.1);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + _animationController.value * 0.1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 70, color: iconColor),
          ),
        );
      },
    );
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
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
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
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
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
                                  child: Text(
                                    _statusMessage,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_statusMessage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.all(16),
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
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else if (_isCreatingProfile)
                        Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
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
                                  child: const Text(
                                    'Création de votre profil...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_isEmailVerified)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.all(16),
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
                              child: Text(
                                'Votre email a été vérifié !',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else if (widget.action == null)
                        ClipRRect(
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
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
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Nous avons envoyé un email de vérification à :',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontFamily: 'Inter',
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
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email ??
                                          'Adresse email non disponible',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Veuillez vérifier votre boîte de réception et cliquer sur le lien de vérification.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            bottom: 16.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.all(16),
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
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontFamily: 'Inter',
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      if (!_isEmailVerified &&
                          !_isCreatingProfile &&
                          widget.action == null)
                        Column(
                          children: [
                            if (_resendTimeout > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Vous pourrez renvoyer dans $_resendTimeout secondes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                          fontFamily: 'Inter',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            CustomButton(
                              text:
                                  _canResendEmail
                                      ? 'Renvoyer l\'email de vérification'
                                      : 'Renvoyer dans $_resendTimeout secondes',
                              isLoading: _isProcessing,
                              onPressed:
                                  _canResendEmail
                                      ? _resendVerificationEmail
                                      : null,
                              textColor: Colors.white,
                              gradient: LinearGradient(
                                colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                              ),
                              borderRadius: 12,
                              textSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              elevation: 0,
                              shadowColor: Color(0xFFD43C38).withOpacity(0.4),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      if (!_isCreatingProfile && !_isProcessing)
                        TextButton.icon(
                          icon: const Icon(
                            Icons.login,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Retour à la connexion',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
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
                            foregroundColor: Colors.white,
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
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final double borderRadius;
  final double textSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double elevation;
  final Color? shadowColor;

  const CustomButton({
    Key? key,
    required this.text,
    required this.isLoading,
    this.onPressed,
    required this.textColor,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = 8,
    this.textSize = 16,
    this.fontWeight,
    this.fontFamily,
    this.elevation = 0,
    this.shadowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || onPressed == null ? null : onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A65)),
                strokeWidth: 3,
              ),
            Center(
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isLoading || onPressed == null
                          ? Colors.white.withOpacity(0.5)
                          : textColor,
                  fontSize: textSize,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  fontFamily: fontFamily,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
