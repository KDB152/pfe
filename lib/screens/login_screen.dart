import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pfe/widgets/fire_detection_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/disabled_screen.dart';
import '../screens/verify_email_screen.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          // Connexion
          UserCredential result = await _authService.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

          // Vérifier si le compte a été marqué comme supprimé
          UserService _userService = UserService();
          bool isDeleted = await _userService.checkIfUserDeleted(
            result.user!.uid,
          );

          if (isDeleted) {
            // Le compte a été supprimé par un admin
            // Déconnecter l'utilisateur
            await _authService.signOut();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ce compte a été supprimé par un administrateur',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Vérifier si le compte est actif
          bool isActive = await _authService.isUserActive(result.user!.uid);
          if (!isActive) {
            // Déconnecter l'utilisateur si son compte est désactivé
            await _authService.signOut();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Votre compte a été désactivé par un administrateur',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Si tout est OK, rediriger vers l'accueil
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
                _errorMessage =
                    'No user found with this email. Please register first.';
                break;
              case 'wrong-password':
                _errorMessage = 'Your password is incorrect.';
                break;
              case 'invalid-email':
                _errorMessage = 'Please enter a valid email address.';
                break;
              case 'user-disabled':
                _errorMessage = 'This account has been disabled.';
                break;
              default:
                _errorMessage =
                    'Votre e-mail et/ou mot de passe incorrect(s) !';
            }
          });
        } catch (e) {
          setState(
            () =>
                _errorMessage = 'Votre e-mail et/ou mot de passe incorrect(s)',
          );
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
                  SizedBox(height: 20),
                  // Logo et titre
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
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Restez en sécurité grâce à la détection des incendies ',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 187, 183, 183),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Titre de la page
                  Text(
                    'Se Connecter',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Formulaire
                  CustomTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    hint: 'Entrer votre e-mail',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 187, 183, 183),
                    ),
                    prefixIcon: Icons.email_outlined,
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
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),

                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                              activeColor: const Color.fromARGB(
                                255,
                                187,
                                183,
                                183,
                              ), // Couleur de fond quand coché
                              checkColor:
                                  Colors.white, // Couleur de la coche (✓)
                              side: const BorderSide(
                                // Bordure personnalisée
                                color: Color.fromARGB(
                                  255,
                                  187,
                                  183,
                                  183,
                                ), // Couleur du cadre
                                width: 2, // Épaisseur du cadre
                              ),
                            ),
                          ),

                          SizedBox(width: 10),
                          Text(
                            'Se mémoriser',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 187, 183, 183),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 187, 183, 183),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 189, 26, 15),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Login button
                  CustomButton(
                    text: 'SE CONNECTER',
                    isLoading: _isLoading,
                    onPressed: _login,
                    textColor: const Color.fromARGB(255, 255, 255, 255),
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Vous n'avez pas un compte ?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Créer un compte',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 212, 211, 211),
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
