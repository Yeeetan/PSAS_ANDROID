import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

// Values from your google-services.json
const _firebaseOptions = FirebaseOptions(
  apiKey:            'AIzaSyB7JeOPrBXvZ-Z15aIdOnZKb19Ca6DqRbM',
  appId:             '1:956340387437:android:77353bfe0f9f06c16b0964',
  messagingSenderId: '956340387437',
  projectId:         'psas-5b61e',
  databaseURL:       'https://psas-5b61e-default-rtdb.asia-southeast1.firebasedatabase.app/',
  storageBucket:     'psas-5b61e.appspot.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: _firebaseOptions);
  } catch (e) {

    debugPrint('Firebase is already running: $e');
  }

  runApp(const ProviderScope(child: PSASApp()));
}

class PSASApp extends ConsumerWidget {
  const PSASApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PSAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}