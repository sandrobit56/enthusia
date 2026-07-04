// File: lib/main.dart
// App: Enthusia
// Description: App entry point. Sets up MaterialApp with Inter font
// and shows the first screen.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/tokens.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();
  runApp(const EnthusiaApp());
}

class EnthusiaApp extends StatelessWidget {
  const EnthusiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.instance.navigatorKey,
      title: 'Enthusia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
