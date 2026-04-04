import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDfC5Hg-XzILBuZJZC4OkAP3riAb0cdGiQ',
    appId: '1:838604269258:web:b358d6ef0cc01700b1b633',
    messagingSenderId: '838604269258',
    projectId: 'ai-assistant-i70b9',
    authDomain: 'ai-assistant-i70b9.firebaseapp.com',
    storageBucket: 'ai-assistant-i70b9.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDG878xTyifpD5jXEjqJYBur4jdyeDg-dQ',
    appId: '1:838604269258:ios:a51912e937f95897b1b633',
    messagingSenderId: '838604269258',
    projectId: 'ai-assistant-i70b9',
    storageBucket: 'ai-assistant-i70b9.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDG878xTyifpD5jXEjqJYBur4jdyeDg-dQ',
    appId: '1:838604269258:ios:a51912e937f95897b1b633',
    messagingSenderId: '838604269258',
    projectId: 'ai-assistant-i70b9',
    storageBucket: 'ai-assistant-i70b9.firebasestorage.app',
    iosBundleId: 'com.example.flutterApp',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDA7dSsC1DBZMI8HLBBhLr9nr52l9JW0I',
    appId: '1:838604269258:android:11e3d556064df0f7b1b633',
    messagingSenderId: '838604269258',
    projectId: 'ai-assistant-i70b9',
    storageBucket: 'ai-assistant-i70b9.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDfC5Hg-XzILBuZJZC4OkAP3riAb0cdGiQ',
    appId: '1:838604269258:web:81fcb244cf46f143b1b633',
    messagingSenderId: '838604269258',
    projectId: 'ai-assistant-i70b9',
    authDomain: 'ai-assistant-i70b9.firebaseapp.com',
    storageBucket: 'ai-assistant-i70b9.firebasestorage.app',
  );

}