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

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase
  await Firebase.initializeApp();

  // Notifications (FCM + local)
  await NotificationService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const CareWatchApp(),
    ),
  );
}

class CareWatchApp extends StatelessWidget {
  const CareWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareWatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AppProvider, bool>((p) => p.loggedIn);
    return loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
