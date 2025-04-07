import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/users_comments_screen.dart';
import 'screens/intro_screen.dart';
import 'models/sensor_data_model.dart';
import 'services/notification_sevice.dart';

// Fonction de niveau supérieur pour gérer les notifications en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  if (message.notification != null) {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification!.title ?? 'Alerte',
      description: message.notification!.body ?? 'Aucune description',
      timestamp: DateTime.now(),
      type: _mapMessageToAlertType(message),
    );

    // Sauvegarder la notification dans Firestore
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(alert.id)
          .set({
            'title': alert.title,
            'description': alert.description,
            'timestamp': Timestamp.fromDate(alert.timestamp),
            'type': alert.type.toString().split('.').last,
          });
    } catch (e) {
      print(
        'Erreur lors de la sauvegarde de la notification en arrière-plan: $e',
      );
    }
  }
}

// Fonction pour mapper le type de message à AlertType
AlertType _mapMessageToAlertType(RemoteMessage message) {
  if (message.data.containsKey('type')) {
    switch (message.data['type']) {
      case 'smoke':
        return AlertType.smoke;
      case 'co2':
        return AlertType.co2;
      case 'test':
        return AlertType.test;
      case 'falseAlarm':
        return AlertType.falseAlarm;
      case 'systemFailure':
        return AlertType.systemFailure;
      default:
        return AlertType.info;
    }
  }
  return AlertType.info;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialiser Firebase Messaging
  await NotificationService.initialize();

  // Configurer le gestionnaire de notifications en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Fixer l'orientation de l'écran en mode portrait uniquement
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FireDetectorApp());
}

class FireDetectorApp extends StatelessWidget {
  const FireDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Détecteur Incendie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dividerTheme: const DividerThemeData(thickness: 1, space: 24),
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.deepOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.grey[850],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.grey[800],
        ),
        dividerTheme: DividerThemeData(
          thickness: 1,
          space: 24,
          color: Colors.grey[700],
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => IntroScreen(),
        '/home':
            (context) =>
                const HomeScreen(userEmail: 'detecteurincendie7@gmail.com'),
        '/login': (context) => LoginScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings':
            (context) =>
                const SettingsScreen(email: 'detecteurincendie7@gmail.com'),
        '/Aide & Support': (context) => const HelpScreen(),
        '/user-management': (context) => const UserManagementScreen(),
        '/users-comments': (context) => const UsersCommentsScreen(),
      },
    );
  }
}
