import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static bool isFirebaseInitialized = false;

  /// Initializes Firebase and enables offline persistence for rural low-connectivity areas
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseInitialized = true;

      // Configure Firestore Settings: disable persistence on Web to prevent stream hangs
      try {
        if (!kIsWeb) {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } else {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: false,
          );
        }
      } catch (persistenceError) {
        debugPrint('Firestore persistence setting note: $persistenceError');
      }

      debugPrint('Firebase successfully initialized with offline persistence enabled.');
    } catch (e) {
      try {
        await Firebase.initializeApp();
        isFirebaseInitialized = true;
        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
          );
        } catch (_) {}
        debugPrint('Firebase initialized via native google-services.json.');
      } catch (fallbackError) {
        isFirebaseInitialized = false;
        debugPrint('Firebase initialization note (running with offline cache/mock fallback): $fallbackError');
      }
    }
  }
}
