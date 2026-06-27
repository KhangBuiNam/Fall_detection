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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Đăng xuất', style: TextStyle(color: AppTheme.textPrim)),
        content: const Text('Bạn có chắc muốn đăng xuất?',
            style: TextStyle(color: AppTheme.textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppTheme.critical)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Tài khoản ──
          const _SecHeader('Tài khoản'),
          _Card(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withOpacity(0.15),
                      ),
                      child: Center(
                        child: Text(
                          prov.username.isNotEmpty
                              ? prov.username[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                              color: AppTheme.accent,
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
                        const Text('Người chăm sóc',
                            style: TextStyle(
                                color: AppTheme.textSec, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    const _Badge('Đang hoạt động', AppTheme.normal),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: AppTheme.textSec.withOpacity(0.1)),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );
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
                          child: const Icon(Icons.manage_accounts_outlined,
                              color: AppTheme.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đổi tên đăng nhập & mật khẩu',
                                style: TextStyle(
                                    color: AppTheme.textPrim,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Cập nhật thông tin đăng nhập',
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

          // ── Nguồn dữ liệu ──
          const _SecHeader('Nguồn dữ liệu'),
          _Card(
            child: Column(
              children: [
                _Row(
                    Icons.cloud_outlined,
                    AppTheme.accent,
                    'Firebase Realtime Database',
                    'Đồng bộ real-time — không cần nhập địa chỉ server',
                    trailing: const _Badge('Đã kết nối', AppTheme.normal)),
                const _Div(),
                _Row(Icons.sync_rounded, AppTheme.spo2Line, 'Đồng bộ dữ liệu',
                    'Cập nhật ngay khi Raspberry Pi gửi dữ liệu'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Thông báo ──
          const _SecHeader('Thông báo'),
          _Card(
            child: Column(
              children: [
                _Row(Icons.notifications_active_outlined, AppTheme.accent,
                    'Thông báo trên thiết bị', 'Báo động khi phát hiện té ngã',
                    trailing: const _Badge('Đang bật', AppTheme.normal)),
                const _Div(),
                _Row(Icons.timer_outlined, AppTheme.warning,
                    'Thời gian chờ giữa các cảnh báo', 'Tối thiểu 30 giây',
                    trailing: const Text('30s',
                        style:
                            TextStyle(color: AppTheme.textSec, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Ngưỡng cảnh báo (KHỚP với Pi) ──
          const _SecHeader('Ngưỡng cảnh báo'),
          _Card(
            child: Column(
              children: [
                _Row(Icons.favorite_outline_rounded, AppTheme.hrLine,
                    'Nhịp tim', 'Cảnh báo khi < 50 hoặc > 120 bpm'),
                const _Div(),
                _Row(Icons.water_drop_outlined, AppTheme.spo2Line, 'SpO2',
                    'Cảnh báo khi < 90%'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Thông tin ──
          const _SecHeader('Thông tin'),
          _Card(
            child: Column(
              children: [
                _Row(Icons.info_outline_rounded, AppTheme.textSec, 'Phiên bản',
                    null,
                    trailing: const Text('1.0.0',
                        style:
                            TextStyle(color: AppTheme.textSec, fontSize: 13))),
                const _Div(),
                _Row(Icons.memory_rounded, AppTheme.textSec, 'Nền tảng', null,
                    trailing: const Text('ESP32 + Raspberry Pi 4',
                        style:
                            TextStyle(color: AppTheme.textSec, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.critical, size: 18),
              label: const Text('Đăng xuất',
                  style: TextStyle(
                      color: AppTheme.critical,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.critical.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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
                letterSpacing: 1.0)),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
        ),
        child: child,
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

class _Div extends StatelessWidget {
  const _Div();
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
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      );
}
