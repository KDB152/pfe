import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  final String userEmail;

  const HelpScreen({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactSection(context),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 24),
            _buildUserGuideSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nous contacter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email, color: Colors.deepOrange),
              ),
              title: const Text('Envoyer un email'),
              subtitle: const Text('Notre équipe vous répondra dans les 24h'),
              onTap: () => _sendEmail(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions fréquemment posées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Comment fonctionne le détecteur de fumée?',
              'Notre détecteur de fumée utilise une technologie photoélectrique avancée pour détecter les particules de fumée dans l\'air. Lorsque la fumée est détectée, l\'alarme se déclenche automatiquement.',
            ),
            const Divider(),
            _buildFAQItem(
              'Que faire en cas de fausse alarme?',
              'En cas de fausse alarme, vous pouvez utiliser l\'application pour désactiver temporairement l\'alarme. Assurez-vous toutefois de vérifier qu\'il n\'y a pas de danger réel avant de la désactiver.',
            ),
            const Divider(),
            _buildFAQItem(
              'Comment tester mon système?',
              'Pour tester votre système, utilisez la fonction "Test d\'alarme" dans la section "Actions rapides" de l\'application. Cela déclenchera une séquence de test pour vérifier que tous vos détecteurs fonctionnent correctement.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGuideSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guide d\'utilisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Installation du détecteur'),
              leading: const Icon(Icons.build_outlined),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigation vers le guide d'installation
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Configuration de l\'application'),
              leading: const Icon(Icons.settings_outlined),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigation vers le guide de configuration
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Résolution des problèmes'),
              leading: const Icon(Icons.help_outline),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigation vers le guide de résolution des problèmes
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'detecteurincendie7gmail.com',
      query: encodeQueryParameters({
        'subject': 'Aide - Application Fire Detector',
        'body':
            'Bonjour,\n\nJ\'ai besoin d\'aide concernant l\'application Fire Detector.\n\nCordialement,\n$userEmail',
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application d\'email'),
        ),
      );
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
