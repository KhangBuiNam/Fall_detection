// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/sensor_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareWatch'),
        actions: [
          Consumer<AppProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.connected ? AppTheme.normal : AppTheme.critical,
                      boxShadow: [
                        BoxShadow(
                          color: (p.connected
                                  ? AppTheme.normal
                                  : AppTheme.critical)
                              .withOpacity(0.5),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.connected ? 'Connected' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.connected ? AppTheme.normal : AppTheme.critical,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, prov, _) {
          final s = prov.status;
          return RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.card,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Alert Banner ──
                if (s.fallDetected) ...[
                  _AlertBanner(alert: s.alert),
                  const SizedBox(height: 12),
                ],

                // ── State Card ──
                _StateCard(status: s),
                const SizedBox(height: 16),

                // ── Vitals Row ──
                Row(
                  children: [
                    Expanded(
                        child: _VitalCard(
                      label: 'Heart Rate',
                      value: '${s.heartRate}',
                      unit: 'bpm',
                      icon: Icons.favorite_rounded,
                      color: AppTheme.hrLine,
                      warning: s.heartRate > 0 &&
                          (s.heartRate < 50 || s.heartRate > 130),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _VitalCard(
                      label: 'SpO2',
                      value: '${s.spo2}',
                      unit: '%',
                      icon: Icons.water_drop_rounded,
                      color: AppTheme.spo2Line,
                      warning: s.spo2 > 0 && s.spo2 < 90,
                    )),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Event Card ──
                _EventCard(event: s.event),
                const SizedBox(height: 12),

                // ── Info Card ──
                _InfoCard(status: s),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────── Widgets ───────────────

class _AlertBanner extends StatelessWidget {
  final String alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert == 'CRITICAL';
    final color = isCritical ? AppTheme.critical : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.emergency_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? '🚨 CRITICAL FALL DETECTED' : '⚠️ FALL WARNING',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCritical
                      ? 'Vital signs abnormal — immediate attention needed'
                      : 'Fall event detected — please check patient',
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final SensorStatus status;
  const _StateCard({required this.status});

  Color _alertColor(String alert) => switch (alert) {
        'CRITICAL' => AppTheme.critical,
        'WARNING' => AppTheme.warning,
        'CHECKING' => const Color(0xFF64D2FF),
        'FALSE_ALARM' => const Color(0xFFAC8E68),
        _ => AppTheme.normal,
      };

  IconData _stateIcon(String state) => switch (state) {
        'FALL_CONFIRMED' => Icons.person_off_rounded,
        'PENDING' => Icons.hourglass_top_rounded,
        'FALSE_ALARM' => Icons.check_circle_outline_rounded,
        _ => Icons.person_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(status.alert);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_stateIcon(status.state), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System State',
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
              const SizedBox(height: 2),
              Text(status.state,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.alert,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              warning ? AppTheme.critical.withOpacity(0.5) : c.withOpacity(0.2),
          width: 1.5,
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
                  style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
              if (warning) ...[
                const Spacer(),
                Icon(Icons.warning_rounded, color: AppTheme.critical, size: 14),
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
                      fontSize: 36,
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

class _EventCard extends StatelessWidget {
  final int event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final active = event == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppTheme.warning.withOpacity(0.4)
              : AppTheme.accent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.sensors : Icons.sensors_rounded,
            color: active ? AppTheme.warning : AppTheme.textSec,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text('MPU6050 Shock Sensor',
              style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.warning.withOpacity(0.2)
                  : AppTheme.normal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              active ? 'SHOCK!' : 'Normal',
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

class _InfoCard extends StatelessWidget {
  final SensorStatus status;
  const _InfoCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final ts = status.timestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(status.timestamp * 1000)
        : null;
    final timeStr = ts != null
        ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _row(Icons.access_time_rounded, 'Last Update', timeStr),
          const SizedBox(height: 8),
          _row(Icons.person_rounded, 'Fall Detected',
              status.fallDetected ? 'YES' : 'No',
              color: status.fallDetected ? AppTheme.critical : AppTheme.normal),
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
