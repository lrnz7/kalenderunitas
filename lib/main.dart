import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
export 'screens/main_page.dart';
import 'screens/admin_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Firebase init error: ${snapshot.error}');
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Firebase initialization failed'),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Kalender Unitas SI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF0066CC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0066CC),
              primary: const Color(0xFF0066CC),
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0066CC),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 2,
            ),
          ),
          routes: {
            '/main': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final isAdmin = args is bool ? args : false;
              return MainPage(isAdmin: isAdmin);
            },
            '/admin': (context) => const AdminPage(),
          },
          home: const AppWrapper(),
        );
      },
    );
  }

  Future<bool> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized');
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase init error: $e');
      return false;
    }
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final isAdmin = userSnapshot.data?['isAdmin'] ?? false;
              return MainPage(isAdmin: isAdmin);
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isAdmin': prefs.getBool('isAdmin') ?? false,
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
    };
  }
}
