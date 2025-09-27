// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF2E7DFF);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color softBackground = Color(0xFFF8FAFF);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.softBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardColor: Colors.white,
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardColor: const Color(0xFF1E293B),
    useMaterial3: true,
  );
}
