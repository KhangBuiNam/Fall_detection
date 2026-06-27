// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/alert_labels.dart';
import '../core/constants.dart';
import '../providers/app_provider.dart';
import '../models/sensor_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám sát bệnh nhân'),
        actions: const [_ConnectionDot()],
      ),
      body: Consumer<AppProvider>(
        builder: (context, prov, _) {
          final s = prov.status;
          return RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.card,
            onRefresh: () async =>
                Future.delayed(const Duration(milliseconds: 500)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Banner cảnh báo (SOS hoặc té ngã)
                if (s.sos) ...[
                  const _SosBanner(),
                  const SizedBox(height: 12),
                ] else if (s.fallDetected) ...[
                  _FallBanner(alert: s.alert),
                  const SizedBox(height: 12),
                ],

                _StateCard(status: s),
                const SizedBox(height: 16),

                // Hàng sinh hiệu
                Row(
                  children: [
                    Expanded(
                      child: _VitalCard(
                        label: 'Nhịp tim',
                        value: '${s.heartRate}',
                        unit: 'bpm',
                        icon: Icons.favorite_outline_rounded,
                        color: AppTheme.hrLine,
                        warning: s.heartRate > 0 &&
                            (s.heartRate < kHrLow || s.heartRate > kHrHigh),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalCard(
                        label: 'SpO2',
                        value: '${s.spo2}',
                        unit: '%',
                        icon: Icons.water_drop_outlined,
                        color: AppTheme.spo2Line,
                        warning: s.spo2 > 0 && s.spo2 < kSpo2Critical,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Số bước chân (Pi có gửi steps)
                _StepsCard(steps: s.steps),
                const SizedBox(height: 12),

                _ShockCard(active: s.fallFlag),
                const SizedBox(height: 12),

                _InfoCard(status: s),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────── Chấm kết nối trên AppBar ───────────────
class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (_, p, __) {
        final color = p.connected ? AppTheme.normal : AppTheme.critical;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                p.connected ? 'Đã kết nối' : 'Mất kết nối',
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────── Banner SOS ───────────────
class _SosBanner extends StatelessWidget {
  const _SosBanner();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE5398B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sos_rounded, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('KHẨN CẤP — Nút SOS',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Bệnh nhân yêu cầu trợ giúp ngay lập tức',
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Banner té ngã ───────────────
class _FallBanner extends StatelessWidget {
  final String alert;
  const _FallBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert == 'CRITICAL';
    final color = isCritical ? AppTheme.critical : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical
                ? Icons.report_problem_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'TÉ NGÃ NGUY CẤP' : 'CẢNH BÁO TÉ NGÃ',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  isCritical
                      ? 'Sinh hiệu bất thường — cần can thiệp ngay'
                      : 'Đã phát hiện té ngã — vui lòng kiểm tra bệnh nhân',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Thẻ trạng thái hệ thống ───────────────
class _StateCard extends StatelessWidget {
  final SensorStatus status;
  const _StateCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AlertLabels.alertColor(status.alert);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(AlertLabels.stateIcon(status.state),
                color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trạng thái hệ thống',
                  style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
              const SizedBox(height: 4),
              Text(AlertLabels.stateText(status.state),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AlertLabels.alertText(status.alert),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── Thẻ sinh hiệu ───────────────
class _VitalCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  final bool warning;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final c = warning ? AppTheme.critical : color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              warning ? AppTheme.critical.withOpacity(0.5) : c.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style:
                      const TextStyle(color: AppTheme.textSec, fontSize: 12)),
              if (warning) ...[
                const Spacer(),
                const Icon(Icons.warning_rounded,
                    color: AppTheme.critical, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value == '0' ? '--' : value,
                  style: TextStyle(
                      color: c,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: TextStyle(color: c.withOpacity(0.7), fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── Thẻ số bước chân ───────────────
class _StepsCard extends StatelessWidget {
  final int steps;
  const _StepsCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk_rounded,
              color: AppTheme.accent, size: 22),
          const SizedBox(width: 12),
          const Text('Số bước chân',
              style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
          const Spacer(),
          Text('$steps',
              style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────── Thẻ cảm biến sốc MPU6050 ───────────────
class _ShockCard extends StatelessWidget {
  final bool active;
  const _ShockCard({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppTheme.warning.withOpacity(0.4)
              : AppTheme.accent.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.vibration_rounded,
              color: active ? AppTheme.warning : AppTheme.textSec, size: 22),
          const SizedBox(width: 12),
          const Text('Cảm biến gia tốc (MPU6050)',
              style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.warning.withOpacity(0.18)
                  : AppTheme.normal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              active ? 'Phát hiện sốc' : 'Bình thường',
              style: TextStyle(
                color: active ? AppTheme.warning : AppTheme.normal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Thẻ thông tin ───────────────
class _InfoCard extends StatelessWidget {
  final SensorStatus status;
  const _InfoCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final ts = status.timestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(status.timestamp * 1000)
        : null;
    final timeStr = ts != null
        ? '${ts.hour.toString().padLeft(2, '0')}:'
            '${ts.minute.toString().padLeft(2, '0')}:'
            '${ts.second.toString().padLeft(2, '0')}'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _row(Icons.access_time_rounded, 'Cập nhật lần cuối', timeStr),
          const SizedBox(height: 10),
          _row(
            Icons.personal_injury_outlined,
            'Té ngã',
            status.fallDetected ? 'CÓ' : 'Không',
            color: status.fallDetected ? AppTheme.critical : AppTheme.normal,
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSec),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: AppTheme.textSec, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color ?? AppTheme.textPrim,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
