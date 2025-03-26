import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../screens/login_screen.dart';
import '../screens/verify_email_screen.dart';
import '../widgets/fire_detection_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Register user
        UserCredential userCredential = await _authService
            .registerWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text,
              _usernameController.text.trim(),
            );

        // Navigate to email verification screen
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
              _errorMessage = 'The password is too weak.';
              break;
            case 'email-already-in-use':
              _errorMessage = 'An account already exists with this email.';
              break;
            default:
              _errorMessage = 'Registration failed. Please try again.';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
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
      body: FireDetectionBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_fire_department,
                              color: const Color.fromARGB(255, 255, 0, 0),
                              size: 70,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Détecteur Incendie',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 0, 0),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Restez en sécurité grâce à la détection des incendies',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 187, 183, 183),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Titre de la page
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Formulaire
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Nom d\'utilisateur',
                    hint: 'Entrez votre nom d\'utilisateur',
                    prefixIcon: Icons.person_outline,
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom d\'utilisateur';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    hint: 'Entrer votre e-mail',
                    prefixIcon: Icons.email_outlined,
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
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
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: 'Entrer votre mot de passe',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                    prefixIcon: Icons.lock_outline,
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
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer votre mot de passe',
                    hint: 'Confirmer votre password',
                    prefixIcon: Icons.lock_outline,
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
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
                  SizedBox(height: 24),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Register button
                  CustomButton(
                    text: 'CREER LE COMPTE',
                    isLoading: _isLoading,
                    onPressed: _register,

                    backgroundColor: const Color.fromARGB(0, 192, 15, 15),
                  ),
                  SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Vous avez déjà un compte ?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
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
