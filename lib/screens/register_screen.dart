import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/verify_email_screen.dart';
import '../widgets/fire_detection_background.dart';
import '../utils/constants.dart';
import 'dart:ui';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VerifyEmailScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'weak-password':
              _errorMessage = 'Le mot de passe est trop faible.';
              break;
            case 'email-already-in-use':
              _errorMessage = 'Un compte existe déjà avec cet e-mail.';
              break;
            default:
              _errorMessage = 'Échec de l\'inscription. Veuillez réessayer.';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Une erreur inattendue s\'est produite.';
        });
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
    final double logoSize = AppSizes.width(context, 0.2);
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
                                      'Créez un compte pour une protection optimale',
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
                                'Inscription',
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
                                controller: _usernameController,
                                label: 'Nom d\'utilisateur',
                                hint: 'Entrez votre nom d\'utilisateur',
                                prefixIcon: Icons.person_outline,
                                iconColor: Color(0xFFFF8A65),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
                                borderRadius: 12,
                                focusedBorderColor: Color(0xFFD43C38),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un nom d\'utilisateur';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: spacingMedium),
                              CustomTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                hint: 'Entrez votre e-mail',
                                prefixIcon: Icons.email_outlined,
                                iconColor: Color(0xFFFF8A65),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
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
                                prefixIcon: Icons.lock_outline,
                                iconColor: Color(0xFFFF8A65),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
                                borderRadius: 12,
                                focusedBorderColor: Color(0xFFD43C38),
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: spacingMedium),
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmer le mot de passe',
                                hint: 'Confirmez votre mot de passe',
                                prefixIcon: Icons.lock_outline,
                                iconColor: Color(0xFFFF8A65),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: AppSizes.bodyFontSize(context),
                                  fontFamily: 'Inter',
                                ),
                                borderRadius: 12,
                                focusedBorderColor: Color(0xFFD43C38),
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez confirmer votre mot de passe';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Les mots de passe ne correspondent pas';
                                  }
                                  return null;
                                },
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

                              // Register button
                              SizedBox(
                                height: AppSizes.buttonHeight(context) * 1.1,
                                child: CustomButton(
                                  text: 'CRÉER LE COMPTE',
                                  isLoading: _isLoading,
                                  onPressed: _register,
                                  textColor: Colors.white,
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

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Déjà un compte ?',
                                    style: TextStyle(
                                      fontSize:
                                          AppSizes.bodyFontSize(context) * 0.9,
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginScreen(),
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
                                      'Se connecter',
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

// Updated CustomTextField to include visibility toggle for password fields
class CustomTextField extends StatefulWidget {
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
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText =
        widget.isPassword; // Initially obscure if it's a password field
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: widget.labelStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: AppSizes.bodyFontSize(context),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'Inter',
            ),
            prefixIcon:
                widget.prefixIcon != null
                    ? Icon(
                      widget.prefixIcon,
                      color: widget.iconColor ?? Colors.white.withOpacity(0.7),
                      size: 20,
                    )
                    : null,
            suffixIcon:
                widget.isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: _toggleVisibility,
                    )
                    : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.focusedBorderColor ?? Colors.white,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: Color(0xFFD43C38)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: Color(0xFFD43C38), width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}

// Reusing CustomButton from LoginScreen
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
