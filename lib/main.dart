import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  final appState = AppState();
  await appState.initialize();

  runApp(
    ChangeNotifierProvider.value(value: appState, child: const LocShareApp()),
  );
}

Future<void> _initializeFirebase() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return Firebase.initializeApp();
  }

  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
