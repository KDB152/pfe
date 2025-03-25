import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/user_service.dart';
import '../widgets/fire_detection_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        // Vérifier d'abord si l'email existe dans Firestore
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

        // Si l'email existe, procéder à la réinitialisation
        await _authService.resetPassword(_emailController.text.trim());
        setState(() {
          _message =
              'Un email de réinitialisation a été envoyé à votre adresse email.';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mot de passe oublié',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FireDetectionBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24),

                  // Titre
                  Text(
                    'Réinitialiser votre mot de passe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Instructions
                  Text(
                    'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation du mot de passe.',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Email input
                  CustomTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    hint: 'Entrez votre adresse e-mail',
                    prefixIcon: Icons.email_outlined,
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
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
                  SizedBox(height: 32),

                  // Message
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Reset button
                  CustomButton(
                    text: 'REINITIALISER VOTRE MOT DE PASSE',
                    isLoading: _isLoading,
                    onPressed: _resetPassword,

                    backgroundColor: const Color.fromARGB(216, 212, 46, 46),
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
