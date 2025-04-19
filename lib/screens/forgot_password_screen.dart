import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/fire_detection_background.dart';
import '../utils/constants.dart';
import 'dart:ui';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;
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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        final userService = UserService();
        final userExists = await userService.checkEmailExists(
          _emailController.text.trim(),
        );

        if (!userExists) {
          setState(() {
            _message = "Aucun compte lié à cette adresse e-mail";
            _isSuccess = false;
            _isLoading = false;
          });
          return;
        }

        await _authService.resetPassword(_emailController.text.trim());
        setState(() {
          _message =
              'Un lien de réinitialisation a été envoyé à votre adresse e-mail.';
          _isSuccess = true;
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _message = "Aucun compte lié à cette adresse e-mail";
          } else {
            _message = 'Échec de l\'envoi : ${e.message}';
          }
          _isSuccess = false;
        });
      } catch (e) {
        setState(() {
          _message = 'Échec de l\'envoi : ${e.toString()}';
          _isSuccess = false;
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
    final double spacingLarge = AppSizes.height(context, 0.025);
    final double spacingMedium = AppSizes.height(context, 0.015);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Mot de passe oublié',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppSizes.titleFontSize(context) * 0.9,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD43C38).withOpacity(0.8),
                Color(0xFFFF8A65).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                              SizedBox(height: spacingLarge),

                              // Title
                              Text(
                                'Réinitialiser votre mot de passe',
                                style: TextStyle(
                                  fontSize: AppSizes.titleFontSize(context),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacingMedium),

                              // Instructions
                              Text(
                                'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
                                style: TextStyle(
                                  fontSize:
                                      AppSizes.bodyFontSize(context) * 0.9,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacingLarge * 1.5),

                              // Email input
                              CustomTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                hint: 'Entrez votre adresse e-mail',
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
                                    return 'Veuillez entrer votre e-mail';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Veuillez entrer un e-mail valide';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: spacingLarge),

                              // Message
                              if (_message.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: spacingMedium,
                                  ),
                                  child: Text(
                                    _message,
                                    style: TextStyle(
                                      color:
                                          _isSuccess
                                              ? Colors.greenAccent
                                              : Color(0xFFD43C38),
                                      fontSize: AppSizes.bodyFontSize(context),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              // Reset button
                              SizedBox(
                                height: AppSizes.buttonHeight(context) * 1.1,
                                child: CustomButton(
                                  text: 'RÉINITIALISER LE MOT DE PASSE',
                                  isLoading: _isLoading,
                                  onPressed: _resetPassword,
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

// Reusing CustomTextField from LoginScreen/RegisterScreen
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

// Reusing CustomButton from LoginScreen/RegisterScreen
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
