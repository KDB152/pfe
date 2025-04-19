import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/fire_detection_background.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/disabled_screen.dart';
import '../screens/verify_email_screen.dart';
import '../services/user_service.dart';
import '../screens/deleted_screen.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Chargement des identifiants sauvegardés
  _loadUserEmailPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe) {
        var email = prefs.getString('email') ?? '';
        var password = prefs.getString('password') ?? '';

        setState(() {
          _rememberMe = true;
          _emailController.text = email;
          _passwordController.text = password;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Sauvegarde des identifiants
  _saveUserEmailPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _saveUserEmailPassword();

        try {
          UserCredential result = await _authService.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

          UserService _userService = UserService();
          bool isDeleted = await _userService.checkIfUserDeleted(
            result.user!.uid,
          );

          if (isDeleted) {
            await _authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ce compte a été supprimé par un administrateur',
                  ),
                  backgroundColor: Color(0xFFD43C38),
                ),
              );
            }
            return;
          }

          bool isActive = await _authService.isUserActive(result.user!.uid);
          if (!isActive) {
            await _authService.signOut();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DisabledScreen()),
              );
            }
            return;
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomeScreen(
                      userEmail: _authService.getCurrentUserEmail(),
                    ),
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          setState(() {
            switch (e.code) {
              case 'user-not-found':
                _errorMessage = 'Aucun utilisateur trouvé avec cet email.';
                break;
              case 'wrong-password':
                _errorMessage = 'Mot de passe incorrect.';
                break;
              case 'invalid-email':
                _errorMessage = 'Veuillez entrer un email valide.';
                break;
              case 'user-disabled':
                _errorMessage = 'Ce compte a été désactivé.';
                break;
              case 'email-not-verified':
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerifyEmailScreen(),
                    ),
                  );
                }
                return;
              default:
                _errorMessage = 'Email et/ou mot de passe incorrect(s).';
            }
          });
        } catch (e) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DeletedScreen()),
            );
          }
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double contentPadding = AppSizes.contentPadding(context);
    final double logoSize = AppSizes.width(context, 0.2); // Reduced for balance
    final double spacingLarge = AppSizes.height(context, 0.025);
    final double spacingMedium = AppSizes.height(context, 0.015);
    final double spacingSmall = AppSizes.height(context, 0.008);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: FireDetectionBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(contentPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(contentPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo and title
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFD43C38),
                                            Color(0xFFFF8A65),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFFD43C38,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.local_fire_department,
                                          color: Colors.white,
                                          size: logoSize * 0.6,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: spacingMedium),
                                    Text(
                                      'Détecteur Incendie',
                                      style: TextStyle(
                                        fontSize:
                                            AppSizes.titleFontSize(context) *
                                            1.1,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: spacingSmall),
                                    Text(
                                      'Protégez-vous avec une détection avancée',
                                      style: TextStyle(
                                        fontSize:
                                            AppSizes.bodyFontSize(context) *
                                            0.9,
                                        color: Colors.white.withOpacity(0.8),
                                        fontFamily: 'Inter',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: spacingLarge * 1.5),

                              // Page title
                              Text(
                                'Connexion',
                                style: TextStyle(
                                  fontSize: AppSizes.titleFontSize(context),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacingLarge),

                              // Form fields
                              CustomTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                hint: 'Entrez votre e-mail',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
                                prefixIcon: Icons.email_outlined,
                                iconColor: Color(0xFFFF8A65),
                                borderRadius: 12,
                                focusedBorderColor: Color(0xFFD43C38),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: spacingMedium),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                hint: 'Entrez votre mot de passe',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
                                prefixIcon: Icons.lock_outline,
                                iconColor: Color(0xFFFF8A65),
                                borderRadius: 12,
                                focusedBorderColor: Color(0xFFD43C38),
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: spacingSmall),

                              // Remember me & Forgot Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 1.1,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value!;
                                            });
                                          },
                                          activeColor: Color(0xFFD43C38),
                                          checkColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Se souvenir',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize:
                                              AppSizes.bodyFontSize(context) *
                                              0.9,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: contentPadding * 0.5,
                                        vertical: spacingSmall,
                                      ),
                                    ),
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        color: Color(0xFFFF8A65),
                                        fontSize:
                                            AppSizes.bodyFontSize(context) *
                                            0.9,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacingLarge),

                              // Error message
                              if (_errorMessage.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: spacingMedium,
                                  ),
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Color(0xFFD43C38),
                                      fontSize: AppSizes.bodyFontSize(context),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              // Login button
                              SizedBox(
                                height: AppSizes.buttonHeight(context) * 1.1,
                                child: CustomButton(
                                  text: 'SE CONNECTER',
                                  isLoading: _isLoading,
                                  onPressed: _login,
                                  textColor: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFD43C38),
                                      Color(0xFFFF8A65),
                                    ],
                                  ),
                                  borderRadius: 12,
                                  textSize: AppSizes.subtitleFontSize(context),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  elevation: 0,
                                  shadowColor: Color(
                                    0xFFD43C38,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              SizedBox(height: spacingLarge),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pas de compte ?",
                                    style: TextStyle(
                                      fontSize:
                                          AppSizes.bodyFontSize(context) * 0.9,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => RegisterScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: contentPadding * 0.5,
                                        vertical: spacingSmall,
                                      ),
                                    ),
                                    child: Text(
                                      'Créer un compte',
                                      style: TextStyle(
                                        color: Color(0xFFFF8A65),
                                        fontSize:
                                            AppSizes.bodyFontSize(context) *
                                            0.9,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacingLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
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

// Updated CustomTextField for modern look
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextStyle? labelStyle;
  final IconData? prefixIcon;
  final Color? iconColor;
  final bool isPassword;
  final String? Function(String?)? validator;
  final double borderRadius;
  final Color? focusedBorderColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.labelStyle,
    this.prefixIcon,
    this.iconColor,
    this.isPassword = false,
    this.validator,
    this.borderRadius = 8,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: AppSizes.bodyFontSize(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'Inter',
            ),
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      color: iconColor ?? Colors.white.withOpacity(0.7),
                      size: 20,
                    )
                    : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: focusedBorderColor ?? Colors.white,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Color(0xFFD43C38)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: Color(0xFFD43C38), width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// Updated CustomButton for modern look
class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
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
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.textColor,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = 8,
    this.textSize = 16,
    this.fontWeight,
    this.fontFamily,
    this.elevation = 0,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A65)),
                strokeWidth: 3,
              ),
            Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isLoading ? Colors.transparent : textColor,
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
