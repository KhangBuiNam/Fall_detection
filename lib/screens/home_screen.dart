// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'chart_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _pages = const [
    DashboardScreen(),
    ChartScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alert = context.select<AppProvider, String>((p) => p.status.alert);
    final sos = context.select<AppProvider, bool>((p) => p.status.sos);
    final connected = context.select<AppProvider, bool>((p) => p.connected);

    // Hiện chấm đỏ khi có SOS hoặc cảnh báo té ngã
    final showDot =
        connected && (sos || alert == 'CRITICAL' || alert == 'WARNING');
    final dotColor =
        sos || alert == 'CRITICAL' ? AppTheme.critical : AppTheme.warning;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.accent.withOpacity(0.12), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textSec,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.monitor_heart_outlined),
                  if (showDot)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.monitor_heart),
              label: 'Giám sát',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Biểu đồ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}
