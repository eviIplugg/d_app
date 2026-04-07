// GENERATED-LIKE FILE (manual): Firebase options for all platforms.
// Note: Web appId should ideally be the WEB app id from Firebase console.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // Not configured in this repo yet; will use the Android project values
        // to keep compilation simple for desktop builds.
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCzTGZZb-HuyjQLHZBU2ncR48YhBguf9Uo',
    appId: '1:483363879285:android:b766460879403c0e307b3c',
    messagingSenderId: '483363879285',
    projectId: 'dating-app-34f38',
    authDomain: 'dating-app-34f38.firebaseapp.com',
    storageBucket: 'dating-app-34f38.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzTGZZb-HuyjQLHZBU2ncR48YhBguf9Uo',
    appId: '1:483363879285:android:b766460879403c0e307b3c',
    messagingSenderId: '483363879285',
    projectId: 'dating-app-34f38',
    storageBucket: 'dating-app-34f38.firebasestorage.app',
  );
}

