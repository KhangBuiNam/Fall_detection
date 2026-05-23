// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  bool _urlEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
      text: context.read<AppProvider>().baseUrl,
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      _showSnack('Invalid URL — must start with http(s)://', error: true);
      return;
    }
    setState(() => _saving = true);
    await context.read<AppProvider>().updateServerUrl(url);
    setState(() {
      _saving = false;
      _urlEditing = false;
    });
    _showSnack('Server URL updated ✓');
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.critical : AppTheme.normal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title:
            const Text('Sign Out', style: TextStyle(color: AppTheme.textPrim)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: AppTheme.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.critical)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
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
          _SectionHeader(title: 'Account'),
          _Card(
            child: Column(
              children: [
                // Avatar + info row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          prov.username.isNotEmpty
                              ? prov.username[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prov.username,
                            style: const TextStyle(
                                color: AppTheme.textPrim,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        const Text('Caregiver',
                            style: TextStyle(
                                color: AppTheme.textSec, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.normal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Active',
                          style: TextStyle(
                              color: AppTheme.normal,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Divider(height: 1, color: AppTheme.textSec.withOpacity(0.1)),
                const SizedBox(height: 4),
                // Change account row — tappable
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                    // Refresh username sau khi đổi
                    if (context.mounted) {
                      await context.read<AppProvider>().refreshUsername();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded,
                              color: AppTheme.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Change Username & Password',
                                style: TextStyle(
                                    color: AppTheme.textPrim,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Update your login credentials',
                                style: TextStyle(
                                    color: AppTheme.textSec, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textSec, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Server Config ──
          _SectionHeader(title: 'Server Configuration'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_rounded,
                        color: AppTheme.accent, size: 18),
                    const SizedBox(width: 8),
                    const Text('ngrok Server URL',
                        style: TextStyle(
                            color: AppTheme.textPrim,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Spacer(),
                    if (!_urlEditing)
                      TextButton(
                        onPressed: () => setState(() => _urlEditing = true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 30)),
                        child:
                            const Text('Edit', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_urlEditing) ...[
                  TextField(
                    controller: _urlCtrl,
                    style:
                        const TextStyle(color: AppTheme.textPrim, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'https://xxxx.ngrok-free.app',
                      hintStyle: const TextStyle(
                          color: AppTheme.textSec, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppTheme.accent.withOpacity(0.6)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSec, size: 16),
                        onPressed: () => _urlCtrl.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _urlEditing = false),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSec),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Save',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: prov.baseUrl));
                      _showSnack('URL copied to clipboard');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              prov.baseUrl.isEmpty
                                  ? 'Not configured'
                                  : prov.baseUrl,
                              style: TextStyle(
                                color: prov.baseUrl.isEmpty
                                    ? AppTheme.critical
                                    : AppTheme.textSec,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.copy_rounded,
                              color: AppTheme.textSec, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: prov.connected
                              ? AppTheme.normal
                              : AppTheme.critical,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        prov.connected ? 'Connected' : 'Not reachable',
                        style: TextStyle(
                          color: prov.connected
                              ? AppTheme.normal
                              : AppTheme.critical,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Notification ──
          _SectionHeader(title: 'Notifications'),
          _Card(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.notifications_active_rounded,
                  iconColor: AppTheme.accent,
                  title: 'Local Notifications',
                  subtitle: 'Alerts when fall is detected (app open)',
                  trailing: _Badge('Enabled', AppTheme.normal),
                ),
                _Divider(),
                _SettingRow(
                  icon: Icons.alarm_rounded,
                  iconColor: AppTheme.warning,
                  title: 'Alert Cooldown',
                  subtitle: 'Min 30s between notifications',
                  trailing: const Text('30s',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Thresholds ──
          _SectionHeader(title: 'Alert Thresholds'),
          _Card(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.favorite_rounded,
                  iconColor: AppTheme.hrLine,
                  title: 'Heart Rate',
                  subtitle: 'Triggers CRITICAL alert',
                  trailing: const Text('< 50 or > 130 bpm',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
                ),
                _Divider(),
                _SettingRow(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppTheme.spo2Line,
                  title: 'SpO2',
                  subtitle: 'Triggers CRITICAL alert',
                  trailing: const Text('< 90%',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ──
          _SectionHeader(title: 'About'),
          _Card(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppTheme.textSec,
                  title: 'Version',
                  trailing: const Text('1.0.0',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
                ),
                _Divider(),
                _SettingRow(
                  icon: Icons.memory_rounded,
                  iconColor: AppTheme.textSec,
                  title: 'Platform',
                  trailing: const Text('ESP32 + Raspberry Pi',
                      style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Logout ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.critical, size: 18),
              label: const Text('Sign Out',
                  style: TextStyle(
                      color: AppTheme.critical,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.critical.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.textSec,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );
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
          border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
        ),
        child: child,
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 20,
        thickness: 1,
        color: AppTheme.textSec.withOpacity(0.1),
      );
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrim,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppTheme.textSec, fontSize: 11)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      );
}
