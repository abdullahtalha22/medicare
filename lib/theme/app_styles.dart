// lib/theme/app_styles.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  static TextStyle glassyHeading(BuildContext context) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
      shadows: [
        Shadow(
          offset: const Offset(0, 1),
          blurRadius: 6,
          color: Colors.black.withOpacity(0.2),
        )
      ],
    );
  }
}
