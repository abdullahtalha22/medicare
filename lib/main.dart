// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediCare',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,   // ✅ custom light theme
      darkTheme: AppTheme.darkTheme, // ✅ custom dark theme
      home: const SplashScreen(),   // ✅ SplashScreen handles routing logic
    );
  }
}
