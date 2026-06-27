// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo Firebase (cần google-services.json trong android/app/)
  await Firebase.initializeApp();

  // Thông báo cục bộ
  await NotificationService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const FallMonitorApp(),
    ),
  );
}

class FallMonitorApp extends StatelessWidget {
  const FallMonitorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giám sát té ngã',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _Router(),
    );
  }
}

class _Router extends StatelessWidget {
  const _Router();
  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AppProvider, bool>((p) => p.loggedIn);
    return loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
