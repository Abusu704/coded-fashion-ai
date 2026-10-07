import 'package:flutter/material.dart';

class AppColors {
  static const bgTop = Color(0xFF0F0C29);
  static const bgMid = Color(0xFF302B63);
  static const bgBottom = Color(0xFF24243E);
  static const accent = Color(0xFFFF6FB5);
  static const accent2 = Color(0xFF7C5CFF);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgTop,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent2,
      brightness: Brightness.dark,
    ),
  );
}

/// Cross-fade page transition used across the app.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
