// lib/screens/video_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/mjpeg_view.dart';

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
    // Restore portrait when leaving screen
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
    final url = prov.videoUrl;
    final status = prov.status;

    if (_fullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleFullscreen,
          child: Stack(
            children: [
              Center(
                child: url.isEmpty
                    ? _noUrl()
                    : MjpegView(streamUrl: url, fit: BoxFit.contain),
              ),
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
              // Alert overlay
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
          if (url.isNotEmpty)
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
          // Stream card
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: status.fallDetected
                    ? (status.alert == 'CRITICAL'
                            ? AppTheme.critical
                            : AppTheme.warning)
                        .withOpacity(0.6)
                    : AppTheme.accent.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: url.isEmpty
                  ? _noUrl()
                  : Stack(
                      children: [
                        MjpegView(streamUrl: url, fit: BoxFit.cover),
                        // Alert overlay on video
                        if (status.fallDetected)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: _AlertChip(alert: status.alert),
                          ),
                        // Fullscreen button overlay
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
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Status row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Live indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: url.isEmpty ? AppTheme.critical : AppTheme.normal,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (url.isEmpty ? AppTheme.critical : AppTheme.normal)
                                .withOpacity(0.5),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  url.isEmpty ? 'No server URL configured' : 'MJPEG Stream',
                  style: const TextStyle(color: AppTheme.textSec, fontSize: 12),
                ),
                const Spacer(),
                Text('320×240 · MJPEG',
                    style:
                        const TextStyle(color: AppTheme.textSec, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Vitals quick view
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Heart Rate',
                  value: '${status.heartRate}',
                  unit: 'bpm',
                  color: AppTheme.hrLine,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStat(
                  label: 'SpO2',
                  value: '${status.spo2}',
                  unit: '%',
                  color: AppTheme.spo2Line,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStat(
                  label: 'State',
                  value: status.state,
                  unit: '',
                  color: AppTheme.accent,
                  small: true,
                ),
              ),
            ],
          ),

          if (url.isEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Go to Settings and enter your ngrok server URL to start streaming.',
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

  Widget _noUrl() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: AppTheme.textSec, size: 48),
          SizedBox(height: 12),
          Text('No server URL configured',
              style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return Container(
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
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unit.isNotEmpty)
            Text(unit,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ],
      ),
    );
  }
}
