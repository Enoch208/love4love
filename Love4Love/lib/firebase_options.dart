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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDGW1_Z2HOXzfANetBGuFp4WYxDm_Nm3ac',
    appId: '1:1008846494626:web:7a44408993f916fbee30fb',
    messagingSenderId: '1008846494626',
    projectId: 'love4love-d7579',
    authDomain: 'love4love-d7579.firebaseapp.com',
    storageBucket: 'love4love-d7579.appspot.com',
    measurementId: 'G-XBFZZZS4F3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBN38wJ8d7NQp2B4X1iVqk_cVMnCuFVd0k',
    appId: '1:1008846494626:android:7fbe7161538fd148ee30fb',
    messagingSenderId: '1008846494626',
    projectId: 'love4love-d7579',
    storageBucket: 'love4love-d7579.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJXTY_cIZzHZ3TIVFktD0qQd9VlvwIR0A',
    appId: '1:1008846494626:ios:cf42b02cb38f57d0ee30fb',
    messagingSenderId: '1008846494626',
    projectId: 'love4love-d7579',
    storageBucket: 'love4love-d7579.appspot.com',
    androidClientId: '1008846494626-c0di7b2lsvg4j6bk8njac0vs99g3teqf.apps.googleusercontent.com',
    iosClientId: '1008846494626-74kd4hengirmrkgen8373gcuiekdidgt.apps.googleusercontent.com',
    iosBundleId: 'com.example.myProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCJXTY_cIZzHZ3TIVFktD0qQd9VlvwIR0A',
    appId: '1:1008846494626:ios:cf42b02cb38f57d0ee30fb',
    messagingSenderId: '1008846494626',
    projectId: 'love4love-d7579',
    storageBucket: 'love4love-d7579.appspot.com',
    androidClientId: '1008846494626-c0di7b2lsvg4j6bk8njac0vs99g3teqf.apps.googleusercontent.com',
    iosClientId: '1008846494626-74kd4hengirmrkgen8373gcuiekdidgt.apps.googleusercontent.com',
    iosBundleId: 'com.example.myProject',
  );

}