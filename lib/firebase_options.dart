// File cấu hình Firebase — sinh từ google-services.json (project attendanceapp-a6ac7)
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
          'DefaultFirebaseOptions chưa cấu hình cho Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions không hỗ trợ nền tảng này.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCe2ZraokgqvUCPYpbHkelbmjNZ-dNLag0',
    appId: '1:593766680189:android:6207ab18f3a1423d191314',
    messagingSenderId: '593766680189',
    projectId: 'attendanceapp-a6ac7',
    storageBucket: 'attendanceapp-a6ac7.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDSVk55RGigSU6ZKjh4AxiFXDSnBaeCUB4',
    appId: '1:593766680189:web:eea4746b09b89492191314',
    messagingSenderId: '593766680189',
    projectId: 'attendanceapp-a6ac7',
    authDomain: 'attendanceapp-a6ac7.firebaseapp.com',
    storageBucket: 'attendanceapp-a6ac7.firebasestorage.app',
    measurementId: 'G-RKS48Y9ZTQ',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAjQeOmUz40W4gjgR55cxY_mwJF9s-gOXc',
    appId: '1:593766680189:ios:0f173213f7384387191314',
    messagingSenderId: '593766680189',
    projectId: 'attendanceapp-a6ac7',
    storageBucket: 'attendanceapp-a6ac7.firebasestorage.app',
    iosBundleId: 'com.example.attendanceapp',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjQeOmUz40W4gjgR55cxY_mwJF9s-gOXc',
    appId: '1:593766680189:ios:0f173213f7384387191314',
    messagingSenderId: '593766680189',
    projectId: 'attendanceapp-a6ac7',
    storageBucket: 'attendanceapp-a6ac7.firebasestorage.app',
    iosBundleId: 'com.example.attendanceapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDSVk55RGigSU6ZKjh4AxiFXDSnBaeCUB4',
    appId: '1:593766680189:web:b86fa4a577d1436f191314',
    messagingSenderId: '593766680189',
    projectId: 'attendanceapp-a6ac7',
    authDomain: 'attendanceapp-a6ac7.firebaseapp.com',
    storageBucket: 'attendanceapp-a6ac7.firebasestorage.app',
    measurementId: 'G-1Q0ZWPZLSE',
  );
}
