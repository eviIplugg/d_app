// Values from android/app/google-services.json and ios/Runner/GoogleService-Info.plist.
// Web: register a Web app in Firebase Console and replace [web] if you use hosting auth.
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
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
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

  /// Matches [ios/Runner/GoogleService-Info.plist] (bundle `com.kuguchev.dapp`).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBxMlIIpxYfTTkA3G89KfYPFBuELxhSfFQ',
    appId: '1:483363879285:ios:f4305f4f4d9c4ff5307b3c',
    messagingSenderId: '483363879285',
    projectId: 'dating-app-34f38',
    storageBucket: 'dating-app-34f38.firebasestorage.app',
    iosClientId: '483363879285-2e6kle0ulkam340ifknejqihkiqub41v.apps.googleusercontent.com',
    iosBundleId: 'com.kuguchev.dapp',
    databaseURL: 'https://dating-app-34f38-default-rtdb.europe-west1.firebasedatabase.app',
  );
}
