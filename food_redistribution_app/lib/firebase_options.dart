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
    apiKey: 'AIzaSyD0vmNqHCbF9C6hxiCG0d8HoT92qzJMs50',
    appId: '1:185924884011:web:184ea2c162490c34313c6e',
    messagingSenderId: '185924884011',
    projectId: 'food-redistribution-plat-86785',
    authDomain: 'food-redistribution-plat-86785.firebaseapp.com',
    storageBucket: 'food-redistribution-plat-86785.firebasestorage.app',
    measurementId: 'G-2WW9VTMLVX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrKdTev_A8Fug6yQAH-Ph9ZK7ECTo1qto',
    appId: '1:185924884011:android:b4bfb376fbc84fb8313c6e',
    messagingSenderId: '185924884011',
    projectId: 'food-redistribution-plat-86785',
    storageBucket: 'food-redistribution-plat-86785.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBTofOryKspNxoDqOctL0j1w8wTrgciMdc',
    appId: '1:185924884011:ios:3d1a4576739990ec313c6e',
    messagingSenderId: '185924884011',
    projectId: 'food-redistribution-plat-86785',
    storageBucket: 'food-redistribution-plat-86785.firebasestorage.app',
    iosClientId: '185924884011-mt32rlagnq9n62vt0sm5odoeftbua114.apps.googleusercontent.com',
    iosBundleId: 'com.example.foodRedistributionApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: '1:123456789:macos:abcdef123456789',
    messagingSenderId: '123456789',
    projectId: 'food-redistribution-platform',
    authDomain: 'food-redistribution-platform.firebaseapp.com',
    storageBucket: 'food-redistribution-platform.appspot.com',
    iosBundleId: 'com.example.foodRedistribution',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0vmNqHCbF9C6hxiCG0d8HoT92qzJMs50',
    appId: '1:185924884011:web:785e7d60ed457faf313c6e',
    messagingSenderId: '185924884011',
    projectId: 'food-redistribution-plat-86785',
    authDomain: 'food-redistribution-plat-86785.firebaseapp.com',
    storageBucket: 'food-redistribution-plat-86785.firebasestorage.app',
    measurementId: 'G-B9M42F5CMX',
  );

}