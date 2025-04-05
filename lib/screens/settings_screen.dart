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

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.deepOrange,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
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
    );
  }

  Widget _buildDangerZone() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion du Compte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'La suppression de votre compte est irréversible. Toutes vos données seront définitivement perdues.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Supprimer mon compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              enabled: false, // Email actuel est désactivé pour modification
              decoration: const InputDecoration(
                labelText: 'Adresse email actuelle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_showNewEmailField) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle adresse email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
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
              icon: Icon(_showNewEmailField ? Icons.save : Icons.edit),
              label: Text(
                _showNewEmailField
                    ? 'Confirmer le changement d\'email'
                    : 'Changer mon email',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
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
                child: const Text('Annuler'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _changePassword();
              },
              icon: const Icon(Icons.save),
              label: const Text('Changer le mot de passe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text(
                'Activer les notifications pour les alertes',
              ),
              value: _isNotificationsEnabled,
              activeColor: Colors.deepOrange,
              onChanged: (value) {
                setState(() {
                  _isNotificationsEnabled = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Son'),
              subtitle: const Text('Activer le son pour les notifications'),
              value: _isSoundEnabled,
              activeColor: Colors.deepOrange,
              onChanged: (value) {
                setState(() {
                  _isSoundEnabled = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text(
                'Activer la vibration pour les notifications',
              ),
              value: _isVibrationEnabled,
              activeColor: Colors.deepOrange,
              onChanged: (value) {
                setState(() {
                  _isVibrationEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Méthode mise à jour pour changer l'email avec Firebase
  Future<void> _updateEmail() async {
    // Validation de l'email
    if (_newEmailController.text.isEmpty ||
        !_newEmailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse e-mail valide'),
        ),
      );
      return;
    }

    // Si l'email n'a pas changé
    if (_newEmailController.text == widget.email) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adresse e-mail inchangée')));
      return;
    }

    // Montrer le chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Réauthentifier l'utilisateur avec le mot de passe actuel
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        // Réauthentifier
        await user.reauthenticateWithCredential(credential);

        // Envoyer un email de vérification à la nouvelle adresse
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

  // Méthode mise à jour pour changer le mot de passe avec Firebase
  Future<void> _changePassword() async {
    // Validation des champs
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    // Vérifier que les nouveaux mots de passe correspondent
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les nouveaux mots de passe ne correspondent pas'),
        ),
      );
      return;
    }

    // Vérifier que le nouveau mot de passe est assez sécurisé (au moins 6 caractères)
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
        ),
      );
      return;
    }

    // Montrer le chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuel
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Réauthentifier l'utilisateur avant de changer le mot de passe
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        // Réauthentifier
        await user.reauthenticateWithCredential(credential);

        // Mettre à jour le mot de passe
        await user.updatePassword(_newPasswordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié avec succès')),
        );

        // Réinitialiser les champs
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
      // Obtenir l'ID de l'utilisateur actuel
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        // Utiliser la nouvelle méthode deleteUser qui gère Firestore et Authentication
        await _authService.deleteUser(currentUser.uid);

        // Rediriger vers l'écran de connexion
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
