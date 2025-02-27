// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyBIfQECAduenH2ZwbsRJaronF41nC93bIQ',
    appId: '1:339279214876:web:1f884d39fd37bf4f5de2d9',
    messagingSenderId: '339279214876',
    projectId: 'md2048-70d60',
    authDomain: 'md2048-70d60.firebaseapp.com',
    storageBucket: 'md2048-70d60.firebasestorage.app',
    measurementId: 'G-19T8GTCPHC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgANw0nSVGdKbiXazgPCn_zTfJ-P-SGCk',
    appId: '1:339279214876:android:6b2b4c59860f9f945de2d9',
    messagingSenderId: '339279214876',
    projectId: 'md2048-70d60',
    storageBucket: 'md2048-70d60.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC92SgW49KKF1QMekrySbBp7tPcxEJBVMg',
    appId: '1:339279214876:ios:ce887511808f2a125de2d9',
    messagingSenderId: '339279214876',
    projectId: 'md2048-70d60',
    storageBucket: 'md2048-70d60.firebasestorage.app',
    iosBundleId: 'com.example.game',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC92SgW49KKF1QMekrySbBp7tPcxEJBVMg',
    appId: '1:339279214876:ios:ce887511808f2a125de2d9',
    messagingSenderId: '339279214876',
    projectId: 'md2048-70d60',
    storageBucket: 'md2048-70d60.firebasestorage.app',
    iosBundleId: 'com.example.game',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBIfQECAduenH2ZwbsRJaronF41nC93bIQ',
    appId: '1:339279214876:web:1006a3425d9b6c475de2d9',
    messagingSenderId: '339279214876',
    projectId: 'md2048-70d60',
    authDomain: 'md2048-70d60.firebaseapp.com',
    storageBucket: 'md2048-70d60.firebasestorage.app',
    measurementId: 'G-1RC2DJHLCK',
  );

}