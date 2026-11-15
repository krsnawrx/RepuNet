import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
    apiKey: 'AIzaSyBgAggFRMXkwMkL4En_zj9mVsxu1NNQxu0',
    appId: '1:841694596350:web:ae11fd9d8b58dae32529af',
    messagingSenderId: '841694596350',
    projectId: 'repunet-86ae6',
    authDomain: 'repunet-86ae6.firebaseapp.com',
    storageBucket: 'repunet-86ae6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAc43Bj28tRw6tKM5Sn38qg8PDEqRP6N9Q',
    appId: '1:841694596350:android:46fe700d9d8d23582529af',
    messagingSenderId: '841694596350',
    projectId: 'repunet-86ae6',
    storageBucket: 'repunet-86ae6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKI9cW_W_q5QsS81CjY7zGVfYbdv7Lvak',
    appId: '1:841694596350:ios:8ddc37c538b0516b2529af',
    messagingSenderId: '841694596350',
    projectId: 'repunet-86ae6',
    storageBucket: 'repunet-86ae6.firebasestorage.app',
    iosBundleId: 'com.repunet.repunet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAKI9cW_W_q5QsS81CjY7zGVfYbdv7Lvak',
    appId: '1:841694596350:ios:8ddc37c538b0516b2529af',
    messagingSenderId: '841694596350',
    projectId: 'repunet-86ae6',
    storageBucket: 'repunet-86ae6.firebasestorage.app',
    iosBundleId: 'com.repunet.repunet',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBgAggFRMXkwMkL4En_zj9mVsxu1NNQxu0',
    appId: '1:841694596350:web:fc93f071d583d5de2529af',
    messagingSenderId: '841694596350',
    projectId: 'repunet-86ae6',
    authDomain: 'repunet-86ae6.firebaseapp.com',
    storageBucket: 'repunet-86ae6.firebasestorage.app',
  );

}