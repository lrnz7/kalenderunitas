import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // WEB CONFIG
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLgx-y4EQRUlm_YkRcK9jJH1c7pkTkWm4',
    appId: '1:527596875858:web:733eeb9d3188ee786faf8b',
    messagingSenderId: '527596875858',
    projectId: 'kalender-unitas',
    authDomain: 'kalender-unitas.firebaseapp.com',
    storageBucket: 'kalender-unitas.firebasestorage.app',
    measurementId: 'G-XXXXXXX', // Ini optional, bisa dikosongin
  );

  // ANDROID CONFIG
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLgx-y4EQRUlm_YkRcK9jJH1c7pkTkWm4',
    appId: '1:527596875858:android:2794c3b273783ffc6faf8b',
    messagingSenderId: '527596875858',
    projectId: 'kalender-unitas',
    storageBucket: 'kalender-unitas.firebasestorage.app',
  );

  // IOS CONFIG
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLgx-y4EQRUlm_YkRcK9jJH1c7pkTkWm4',
    appId: '1:527596875858:ios:429422b084aafc0a6faf8b',
    messagingSenderId: '527596875858',
    projectId: 'kalender-unitas',
    storageBucket: 'kalender-unitas.firebasestorage.app',
    iosBundleId: 'com.unitas.kalender',
  );

  // MACOS CONFIG (sama dengan iOS)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLgx-y4EQRUlm_YkRcK9jJH1c7pkTkWm4',
    appId: '1:527596875858:ios:429422b084aafc0a6faf8b',
    messagingSenderId: '527596875858',
    projectId: 'kalender-unitas',
    storageBucket: 'kalender-unitas.firebasestorage.app',
    iosBundleId: 'com.unitas.kalender',
  );

  // WINDOWS CONFIG (sama dengan web)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCLgx-y4EQRUlm_YkRcK9jJH1c7pkTkWm4',
    appId: '1:527596875858:web:8757250df04c34866faf8b',
    messagingSenderId: '527596875858',
    projectId: 'kalender-unitas',
    authDomain: 'kalender-unitas.firebaseapp.com',
    storageBucket: 'kalender-unitas.firebasestorage.app',
    measurementId: 'G-XXXXXXX',
  );
}