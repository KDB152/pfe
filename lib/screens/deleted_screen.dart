import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class DeletedScreen extends StatelessWidget {
  const DeletedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Compte Supprimé',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Ajout du SingleChildScrollView
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24), // Réduit l'espacement initial
                Container(
                  padding: const EdgeInsets.all(16), // Réduit le padding
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 60, // Réduit la taille de l'icône
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 24), // Réduit l'espacement
                Text(
                  'Compte supprimé',
                  style: TextStyle(
                    fontSize: 22, // Légèrement réduit
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // Réduit l'espacement
                Container(
                  padding: const EdgeInsets.all(16), // Réduit le padding
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Votre compte a été supprimé par un administrateur.',
                        style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18, // Réduit la taille
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Toutes vos données ont été effacées de notre système.',
                              style: TextStyle(
                                fontSize: 14, // Réduit la taille
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18, // Réduit la taille
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pour toute question, contactez-nous à detecteurincendie7@gmail.com',
                              style: TextStyle(
                                fontSize: 14, // Réduit la taille
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Réduit l'espacement
                Container(
                  padding: const EdgeInsets.all(12), // Réduit le padding
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 22, // Réduit la taille
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vous pouvez créer un nouveau compte avec une adresse email différente si vous souhaitez utiliser à nouveau notre service.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // Réduit l'espacement
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(
                      double.infinity,
                      46,
                    ), // Hauteur légèrement réduite
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Retourner à l\'accueil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12), // Réduit l'espacement
                TextButton.icon(
                  icon: const Icon(
                    Icons.help_outline,
                    size: 16,
                  ), // Réduit l'icône
                  label: const Text('Besoin d\'aide ?'),
                  onPressed: () {
                    _showHelpDialog(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10, // Réduit le padding
                      horizontal: 14,
                    ),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16), // Assure un peu d'espace en bas
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Text('Aide'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pourquoi mon compte a-t-il été supprimé ?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les comptes peuvent être supprimés pour diverses raisons, notamment :'
                  '\n\n• Violation des conditions d\'utilisation'
                  '\n• À votre demande'
                  '\n• Inactivité prolongée'
                  '\n• Activités suspectes',
                  style: TextStyle(color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comment puis-je récupérer mes données ?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Une fois qu\'un compte est supprimé, toutes les données associées sont définitivement effacées et ne peuvent pas être récupérées.',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Contacter le support'),
              onPressed: () {
                // Ici, vous pourriez implémenter une fonction pour ouvrir l'email par exemple
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
