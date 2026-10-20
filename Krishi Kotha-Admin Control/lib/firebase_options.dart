import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Krishi Kotha Admin Control Portal.
/// Connected to the same 'krishikotha-app' Firestore project for real-time synchronization.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAE3NMLtENJ6abrQauQQrJ-BorS-K8-LHQ',
    appId: '1:161614701103:web:12c184d7d5b13580791cda',
    messagingSenderId: '161614701103',
    projectId: 'krishikotha-app',
    authDomain: 'krishikotha-app.firebaseapp.com',
    storageBucket: 'krishikotha-app.firebasestorage.app',
    measurementId: 'G-6BB8ZFHR9M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD08a-tSsO4UvZ3wk3JzZQPMeFMOelcK8E',
    appId: '1:161614701103:android:5070d9d7d342e090791cda',
    messagingSenderId: '161614701103',
    projectId: 'krishikotha-app',
    storageBucket: 'krishikotha-app.firebasestorage.app',
  );
}
