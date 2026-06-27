// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Nền tối dịu, không quá xanh neon
  static const Color bg = Color(0xFF121620);
  static const Color surface = Color(0xFF1A1F2B);
  static const Color card = Color(0xFF222836);

  // Màu nhấn xanh dương trầm (thay vì cyan neon 0xFF00C6FF)
  static const Color accent = Color(0xFF3D7EFF);
  static const Color accentSoft = Color(0xFF2D5FCC);

  static const Color textPrim = Color(0xFFE6EAF2);
  static const Color textSec = Color(0xFF94A0B8);

  // Màu trạng thái — dịu hơn, gần với chuẩn y tế
  static const Color critical = Color(0xFFE5484D);
  static const Color warning = Color(0xFFE8A53D);
  static const Color normal = Color(0xFF3DB068);

  // Màu biểu đồ
  static const Color hrLine = Color(0xFFE05D8A);
  static const Color spo2Line = Color(0xFF3D7EFF);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          secondary: accentSoft,
        ),
        // Dùng font hệ thống — không phụ thuộc font Apple
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrim,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: textPrim),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrim),
          bodyMedium: TextStyle(color: textSec),
        ),
      );
}
