import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/user_management_screen.dart';
import 'screens/users_comments_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/SplashScreen.dart';
import 'screens/view_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      themeMode: ThemeMode.system, // Utiliser le thème du système
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/home':
            (context) =>
                const HomeScreen(userEmail: 'detecteurincendie7@gmail.com'),
        '/login': (context) => LoginScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings':
            (context) =>
                const SettingsScreen(email: 'detecteurincendie7@gmail.com'),
        '/Aide & Support': (context) => const HelpScreen(),
        '/live-view': (context) => ViewScreen(),
        '/user-management': (context) => const UserManagementScreen(),
        '/users-comments':
            (context) => const UsersCommentsScreen(), // Ajouter cette route
      },
    );
  }
}
