// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAc1zv1rrm-PnHJEK9aZbtu29Usst3tFJA',
    appId: '1:678426544560:android:d8e66aced0df342ec8ae75',
    messagingSenderId: '678426544560',
    projectId: 'chipin-7fceb',
    storageBucket: 'chipin-7fceb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBm0SX-2U1v-fpEL1zPbncXk6mOtRK3-P8',
    appId: '1:678426544560:ios:af093520aa2d355cc8ae75',
    messagingSenderId: '678426544560',
    projectId: 'chipin-7fceb',
    storageBucket: 'chipin-7fceb.firebasestorage.app',
    iosBundleId: 'com.fynko.ChipIn',
  );
}
