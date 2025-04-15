import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart'; // Importer les constantes
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/fire_detection_background.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/disabled_screen.dart';
import '../screens/verify_email_screen.dart';
import '../services/user_service.dart';
import '../screens/deleted_screen.dart';

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DisabledScreen()),
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
              case 'email-not-verified':
                // Redirect to email verification screen
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
                _errorMessage =
                    'Votre e-mail et/ou mot de passe incorrect(s) ! ';
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
    final double logoSize = AppSizes.width(context, 0.25); // 25% de la largeur
    final double spacingLarge = AppSizes.height(
      context,
      0.03,
    ); // 3% de la hauteur
    final double spacingMedium = AppSizes.height(
      context,
      0.02,
    ); // 2% de la hauteur
    final double spacingSmall = AppSizes.height(
      context,
      0.01,
    ); // 1% de la hauteur

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FireDetectionBackground(
        child: SafeArea(
          child: Center(
            // Centrer tout le contenu
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(contentPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: spacingLarge),

                    // Logo et titre - Centré et adaptatif
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.local_fire_department,
                                color: const Color.fromARGB(255, 255, 0, 0),
                                size:
                                    logoSize * 0.7, // 70% de la taille du logo
                              ),
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          Text(
                            'Détecteur Incendie',
                            style: TextStyle(
                              fontSize: AppSizes.titleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 0, 0),
                            ),
                          ),
                          SizedBox(height: spacingSmall),
                          Text(
                            'Restez en sécurité grâce à la détection \n des incendies',
                            style: TextStyle(
                              fontSize: AppSizes.bodyFontSize(context),
                              color: const Color.fromARGB(255, 187, 183, 183),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingLarge * 1.5),

                    // Titre de la page
                    Text(
                      'Se Connecter',
                      style: TextStyle(
                        fontSize: AppSizes.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 187, 183, 183),
                      ),
                    ),
                    SizedBox(height: spacingLarge),

                    // Formulaire - Adapté avec des tailles proportionnelles
                    CustomTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      hint: 'Entrer votre e-mail',
                      labelStyle: TextStyle(
                        color: const Color.fromARGB(255, 187, 183, 183),
                        fontSize: AppSizes.bodyFontSize(context),
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
                    SizedBox(height: spacingMedium),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      hint: 'Entrer votre mot de passe',
                      labelStyle: TextStyle(
                        color: const Color.fromARGB(255, 187, 183, 183),
                        fontSize: AppSizes.bodyFontSize(context),
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
                    SizedBox(height: spacingSmall),

                    // Remember me & Forgot Password - Adapté
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale:
                                  1.2, // Légèrement plus grand pour être plus visible
                              child: SizedBox(
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
                                  ),
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 187, 183, 183),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Se mémoriser',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 187, 183, 183),
                                fontSize: AppSizes.bodyFontSize(context) * 0.9,
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
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: contentPadding * 0.5,
                              vertical: spacingSmall,
                            ),
                          ),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 187, 183, 183),
                              fontSize: AppSizes.bodyFontSize(context) * 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacingLarge),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: spacingMedium),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 233, 180, 180),
                            fontSize: AppSizes.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login button - Plus grand et plus visible
                    SizedBox(
                      height: AppSizes.buttonHeight(context),
                      child: CustomButton(
                        text: 'SE CONNECTER',
                        isLoading: _isLoading,
                        onPressed: _login,
                        textColor: const Color.fromARGB(255, 255, 255, 255),
                        backgroundColor: const Color.fromARGB(
                          255,
                          180,
                          51,
                          11,
                        ).withOpacity(0.8),
                        textSize: AppSizes.subtitleFontSize(context),
                      ),
                    ),
                    SizedBox(height: spacingLarge),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vous n'avez pas un compte ?",
                          style: TextStyle(
                            fontSize: AppSizes.bodyFontSize(context),
                            color: const Color.fromARGB(255, 187, 183, 183),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
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
                              color: const Color.fromARGB(255, 212, 211, 211),
                              fontSize: AppSizes.bodyFontSize(context),
                              fontWeight: FontWeight.bold,
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
    );
  }
}
