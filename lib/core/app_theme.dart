// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF131929);
  static const Color card = Color(0xFF1C2438);
  static const Color accent = Color(0xFF00C6FF);
  static const Color accentSoft = Color(0xFF0072FF);
  static const Color textPrim = Color(0xFFEAF0FF);
  static const Color textSec = Color(0xFF8899BB);
  static const Color critical = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color normal = Color(0xFF30D158);
  static const Color hrLine = Color(0xFFFF6B9D);
  static const Color spo2Line = Color(0xFF00C6FF);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          secondary: accentSoft,
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrim,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          iconTheme: IconThemeData(color: textPrim),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrim),
          bodyMedium: TextStyle(color: textSec),
        ),
      );
}
