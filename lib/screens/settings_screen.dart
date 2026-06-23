// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                backgroundColor: AppTheme.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppTheme.textPrim)),
                content: const Text('Are you sure?',
                    style: TextStyle(color: AppTheme.textSec)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.textSec))),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.critical))),
                ]));
    if (ok == true && context.mounted) {
      await context.read<AppProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Account ──
          _SecHeader('Account'),
          _Card(
              child: Column(children: [
            Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
                  ),
                  child: Center(
                      child: Text(
                          prov.username.isNotEmpty
                              ? prov.username[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20)))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prov.username,
                    style: const TextStyle(
                        color: AppTheme.textPrim,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const Text('Caregiver',
                    style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
              ]),
              const Spacer(),
              _Badge('Active', AppTheme.normal),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.textSec.withOpacity(0.1)),
            InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()));
                  if (context.mounted) {
                    await context.read<AppProvider>().refreshUsername();
                  }
                },
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.manage_accounts_rounded,
                              color: AppTheme.accent, size: 18)),
                      const SizedBox(width: 12),
                      const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Change Username & Password',
                                style: TextStyle(
                                    color: AppTheme.textPrim,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Update login credentials',
                                style: TextStyle(
                                    color: AppTheme.textSec, fontSize: 11)),
                          ]),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSec, size: 20),
                    ]))),
          ])),
          const SizedBox(height: 20),

          // ── Firebase ──
          _SecHeader('Data Source'),
          _Card(
              child: Column(children: [
            _Row(
                Icons.cloud_rounded,
                AppTheme.accent,
                'Firebase Realtime Database',
                'Real-time sync — no server URL needed',
                trailing: _Badge('Connected', AppTheme.normal)),
            _Div(),
            _Row(Icons.sync_rounded, AppTheme.spo2Line, 'Data Sync',
                'Updates instantly when Pi sends data'),
          ])),
          const SizedBox(height: 20),

          // ── Notifications ──
          _SecHeader('Notifications'),
          _Card(
              child: Column(children: [
            _Row(Icons.notifications_active_rounded, AppTheme.accent,
                'Local Notifications', 'Alert when fall detected',
                trailing: _Badge('Enabled', AppTheme.normal)),
            _Div(),
            _Row(Icons.alarm_rounded, AppTheme.warning, 'Alert Cooldown',
                'Min 30s between alerts',
                trailing: const Text('30s',
                    style: TextStyle(color: AppTheme.textSec, fontSize: 13))),
          ])),
          const SizedBox(height: 20),

          // ── Thresholds ──
          _SecHeader('Alert Thresholds'),
          _Card(
              child: Column(children: [
            _Row(Icons.favorite_rounded, AppTheme.hrLine, 'Heart Rate',
                'CRITICAL when < 50 or > 130 bpm'),
            _Div(),
            _Row(Icons.water_drop_rounded, AppTheme.spo2Line, 'SpO2',
                'CRITICAL when < 90%'),
          ])),
          const SizedBox(height: 20),

          // ── About ──
          _SecHeader('About'),
          _Card(
              child: Column(children: [
            _Row(Icons.info_outline_rounded, AppTheme.textSec, 'Version', null,
                trailing: const Text('1.0.0',
                    style: TextStyle(color: AppTheme.textSec, fontSize: 13))),
            _Div(),
            _Row(Icons.memory_rounded, AppTheme.textSec, 'Platform', null,
                trailing: const Text('ESP32 + Raspberry Pi',
                    style: TextStyle(color: AppTheme.textSec, fontSize: 12))),
          ])),
          const SizedBox(height: 28),

          SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.critical, size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: AppTheme.critical,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.critical.withOpacity(0.4),
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))))),
        ],
      ),
    );
  }
}

class _SecHeader extends StatelessWidget {
  final String t;
  const _SecHeader(this.t);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(t.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.textSec,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withOpacity(0.1))),
      child: child);
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)));
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
      height: 20, thickness: 1, color: AppTheme.textSec.withOpacity(0.1));
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _Row(this.icon, this.iconColor, this.title, this.subtitle,
      {this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(color: AppTheme.textSec, fontSize: 11)),
        ])),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]);
}
