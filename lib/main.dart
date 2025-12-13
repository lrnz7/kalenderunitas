import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- TAMBAH INI
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting Kalender Unitas...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Test Firestore connection
    await _testFirestore();
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
    print('📱 Running in offline mode');
  }
  
  runApp(const MyApp());
}

// Helper function to test Firestore
Future<void> _testFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('app_health').doc('startup').set({
      'app': 'Kalender Unitas',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'healthy',
    });
    print('✅ Firestore test write successful');
  } catch (e) {
    print('⚠️ Firestore test failed: $e');
  }
}

// MyApp tetap sama...
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalender Unitas Sistem Informasi',
      theme: ThemeData(
        primaryColor: const Color(0xFF0066CC),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: const Color(0xFF00A86B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0066CC),
          centerTitle: true,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0066CC),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}