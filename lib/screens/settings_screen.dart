import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String email;

  const SettingsScreen({super.key, required this.email});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _deleteAccountPasswordController =
      TextEditingController();

  bool _isNotificationsEnabled = true;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isLoading = false;
  bool _showNewEmailField = false;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _emailController.text = _authService.getCurrentUserEmail();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _newEmailController.dispose();
    _deleteAccountPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('E-mail'),
                      _buildAccountSection(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Mot de passe'),
                      _buildChangePasswordSection(),
                      const SizedBox(height: 32),
                      _buildDangerZone(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Notifications'),
                      _buildNotificationsSection(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion du Compte',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La suppression de votre compte est irréversible. Toutes vos données seront définitivement perdues.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Supprimer mon compte',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Adresse email actuelle',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    prefixIcon: const Icon(Icons.email, color: Colors.white),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_showNewEmailField) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newEmailController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nouvelle adresse email',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Inter',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Inter',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                    ),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_showNewEmailField) {
                      _updateEmail();
                    } else {
                      setState(() {
                        _showNewEmailField = true;
                      });
                    }
                  },
                  icon: Icon(
                    _showNewEmailField ? Icons.save : Icons.edit,
                    color: Colors.white,
                  ),
                  label: Text(
                    _showNewEmailField
                        ? 'Confirmer le changement d\'email'
                        : 'Changer mon email',
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD43C38),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (_showNewEmailField) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showNewEmailField = false;
                        _newEmailController.clear();
                        _currentPasswordController.clear();
                      });
                    },
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                TextFormField(
                  controller: _currentPasswordController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Changer le mot de passe',
                    style: TextStyle(fontFamily: 'Inter'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD43C38),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                SwitchListTile(
                  title: const Text(
                    'Notifications',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  ),
                  subtitle: Text(
                    'Activer les notifications pour les alertes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  value: _isNotificationsEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFD43C38),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                  onChanged: (value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                  },
                ),
                Divider(color: Colors.white.withOpacity(0.3)),
                SwitchListTile(
                  title: const Text(
                    'Son',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  ),
                  subtitle: Text(
                    'Activer le son pour les notifications',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  value: _isSoundEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFD43C38),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                  onChanged: (value) {
                    setState(() {
                      _isSoundEnabled = value;
                    });
                  },
                ),
                Divider(color: Colors.white.withOpacity(0.3)),
                SwitchListTile(
                  title: const Text(
                    'Vibration',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  ),
                  subtitle: Text(
                    'Activer la vibration pour les notifications',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Inter',
                    ),
                  ),
                  value: _isVibrationEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFD43C38),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                  onChanged: (value) {
                    setState(() {
                      _isVibrationEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateEmail() async {
    if (_newEmailController.text.isEmpty ||
        !_newEmailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse e-mail valide'),
        ),
      );
      return;
    }

    if (_newEmailController.text == widget.email) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adresse e-mail inchangée')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        final AuthService authService = AuthService();
        await authService.verifyBeforeUpdateEmail(_newEmailController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Un email de vérification a été envoyé à votre nouvelle adresse. '
              'Veuillez vérifier votre boîte de réception et suivre les instructions.',
            ),
          ),
        );

        setState(() {
          _showNewEmailField = false;
          _newEmailController.clear();
          _currentPasswordController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la mise à jour de l\'email';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage =
                'Veuillez vous reconnecter pour effectuer cette action';
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
            break;
          case 'email-already-in-use':
            errorMessage = 'Cette adresse email est déjà utilisée';
            break;
          case 'invalid-email':
            errorMessage = 'Adresse email invalide';
            break;
          default:
            errorMessage = 'Le mot de passe actuel est incorrect';
        }
      } else {
        errorMessage = 'Erreur !!';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les nouveaux mots de passe ne correspondent pas'),
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        await user.updatePassword(_newPasswordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié avec succès')),
        );

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la modification du mot de passe';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage =
                'Veuillez vous reconnecter pour effectuer cette action';
            break;
          case 'weak-password':
            errorMessage = 'Le mot de passe est trop faible';
            break;
          case 'wrong-password':
            errorMessage =
                'Les informations d\'identification sont incorrectes';
            break;
          case 'invalid-credential':
            errorMessage = 'Le mot de passe actuel est incorrect !';
            break;
          default:
            errorMessage = 'Erreur: ${e.code}';
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        await _authService.deleteUser(currentUser.uid);

        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre compte a été supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
