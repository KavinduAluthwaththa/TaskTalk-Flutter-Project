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
    apiKey: 'AIzaSyAOVYRIgupAurZup5y1PRh8EUREyt-4n6M',
    appId: '1:448618578101:web:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'voice-todo-list-demo',
    authDomain: 'voice-todo-list-demo.firebaseapp.com',
    storageBucket: 'voice-todo-list-demo.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBP4DLvqXeC2oa_Q5P3EgJJu-xGEfqHQ4o',
    appId: '1:448618578101:android:aa5b6b665ac3effcac3efc',
    messagingSenderId: '448618578101',
    projectId: 'voice-todo-list-demo',
    storageBucket: 'voice-todo-list-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDGI-lOTdhxwjEa7qFP3z7sZuJ1Dk3xqR0',
    appId: '1:448618578101:ios:b8c8b665ac3effcac3efc',
    messagingSenderId: '448618578101',
    projectId: 'voice-todo-list-demo',
    storageBucket: 'voice-todo-list-demo.appspot.com',
    iosBundleId: 'com.example.voicetodolist',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDGI-lOTdhxwjEa7qFP3z7sZuJ1Dk3xqR0',
    appId: '1:448618578101:ios:b8c8b665ac3effcac3efc',
    messagingSenderId: '448618578101',
    projectId: 'voice-todo-list-demo',
    storageBucket: 'voice-todo-list-demo.appspot.com',
    iosBundleId: 'com.example.voicetodolist',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAOVYRIgupAurZup5y1PRh8EUREyt-4n6M',
    appId: '1:448618578101:web:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'voice-todo-list-demo',
    authDomain: 'voice-todo-list-demo.firebaseapp.com',
    storageBucket: 'voice-todo-list-demo.appspot.com',
  );
}
