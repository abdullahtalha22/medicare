import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isOnboardingCompleted = prefs.getBool('isOnboardingCompleted') ?? false;
    bool isRememberMe = prefs.getBool('isRememberMe') ?? false;
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Optional splash delay
    await Future.delayed(const Duration(seconds: 3));

    if (!isOnboardingCompleted) {
      // First-time user → onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (isLoggedIn && isRememberMe) {
      // User logged in and chose Remember Me → home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Existing user → login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF28C76F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/medicine.json',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "MediCare",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Smart Medicine Companion",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
