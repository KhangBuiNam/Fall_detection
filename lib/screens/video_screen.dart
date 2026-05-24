// lib/screens/video_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/webrtc_view.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _fullscreen = false;

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final status = prov.status;
    final whep = prov.whepUrl;

    if (_fullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleFullscreen,
          child: Stack(
            children: [
              Center(child: WebRtcView(whepUrl: whep)),
              // Exit hint
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fullscreen_exit,
                      color: Colors.white70, size: 22),
                ),
              ),
              if (status.fallDetected)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _AlertChip(alert: status.alert),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Live'),
        actions: [
          if (prov.isMediaConfigured)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded),
              onPressed: _toggleFullscreen,
              tooltip: 'Fullscreen',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Video card ──
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: status.fallDetected
                    ? (status.alert == 'CRITICAL'
                            ? AppTheme.critical
                            : AppTheme.warning)
                        .withOpacity(0.7)
                    : AppTheme.accent.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  WebRtcView(whepUrl: whep),
                  if (status.fallDetected)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _AlertChip(alert: status.alert),
                    ),
                  // Fullscreen button
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleFullscreen,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fullscreen,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                  ),
                  // WebRTC badge
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF30D158), size: 7),
                          SizedBox(width: 5),
                          Text('WebRTC · MediaMTX',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Connection info ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: prov.isMediaConfigured
                            ? AppTheme.normal
                            : AppTheme.critical,
                        boxShadow: [
                          BoxShadow(
                            color: (prov.isMediaConfigured
                                    ? AppTheme.normal
                                    : AppTheme.critical)
                                .withOpacity(0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('WHEP Endpoint',
                        style:
                            TextStyle(color: AppTheme.textSec, fontSize: 12)),
                    const Spacer(),
                    Text('MediaMTX :8889',
                        style: const TextStyle(
                            color: AppTheme.textSec, fontSize: 11)),
                  ],
                ),
                if (whep.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            whep,
                            style: const TextStyle(
                                color: AppTheme.textSec,
                                fontSize: 11,
                                fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: whep));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('WHEP URL copied'),
                                backgroundColor: AppTheme.normal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded,
                              color: AppTheme.textSec, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Quick vitals ──
          Row(
            children: [
              Expanded(
                  child: _QuickStat(
                label: 'Heart Rate',
                value: '${status.heartRate}',
                unit: 'bpm',
                color: AppTheme.hrLine,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _QuickStat(
                label: 'SpO2',
                value: '${status.spo2}',
                unit: '%',
                color: AppTheme.spo2Line,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _QuickStat(
                label: 'State',
                value: status.state,
                unit: '',
                color: AppTheme.accent,
                small: true,
              )),
            ],
          ),

          // ── Warning nếu chưa config ──
          if (!prov.isMediaConfigured) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Go to Settings → enter MediaMTX URL\n(e.g. http://100.x.x.x:8889)',
                      style: TextStyle(color: AppTheme.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helper widgets ───

class _AlertChip extends StatelessWidget {
  final String alert;
  const _AlertChip({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert == 'CRITICAL' ? AppTheme.critical : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(alert,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final bool small;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: AppTheme.textSec, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              value == '0' ? '--' : value,
              style: TextStyle(
                  color: color,
                  fontSize: small ? 13 : 20,
                  fontWeight: FontWeight.w700),
            ),
            if (unit.isNotEmpty)
              Text(unit,
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      );
}
