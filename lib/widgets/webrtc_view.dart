// lib/widgets/webrtc_view.dart
//
// WebRTC player dùng WHEP protocol (MediaMTX native support).
// WHEP = WebRTC HTTP Egress Protocol — viewer chỉ cần 1 HTTP POST để kết nối.
//
// Flow:
//   1. POST {whepUrl}          → gửi SDP offer
//   2. Nhận SDP answer từ server
//   3. Set remote description → ICE negotiation tự động
//   4. Render video qua RTCVideoRenderer

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import '../core/app_theme.dart';

class WebRtcView extends StatefulWidget {
  final String whepUrl; // vd: http://100.x.x.x:8889/live/whep

  const WebRtcView({super.key, required this.whepUrl});

  @override
  State<WebRtcView> createState() => _WebRtcViewState();
}

class _WebRtcViewState extends State<WebRtcView> {
  RTCPeerConnection? _pc;
  final _renderer = RTCVideoRenderer();

  _ViewState _state = _ViewState.connecting;
  String? _errorMsg;
  bool _rendererReady = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void didUpdateWidget(WebRtcView old) {
    super.didUpdateWidget(old);
    if (old.whepUrl != widget.whepUrl) {
      _disconnect();
      _connect();
    }
  }

  @override
  void dispose() {
    _disconnect();
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    setState(() => _rendererReady = true);
    _connect();
  }

  // ── Main connect flow ──
  Future<void> _connect() async {
    if (widget.whepUrl.isEmpty) {
      setState(() {
        _state = _ViewState.error;
        _errorMsg =
            'MediaMTX URL not configured.\nGo to Settings and enter the URL.';
      });
      return;
    }

    setState(() {
      _state = _ViewState.connecting;
      _errorMsg = null;
    });

    try {
      // 1. Create PeerConnection (receive-only)
      _pc = await createPeerConnection({
        'iceServers': [
          // Tailscale = LAN, không cần STUN/TURN
          // Nếu cần qua internet thêm: {'urls': 'stun:stun.l.google.com:19302'}
        ],
        'sdpSemantics': 'unified-plan',
      });

      // 2. Add receive-only transceivers
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // 3. Bind remote track → renderer
      _pc!.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams[0];
          if (mounted) setState(() => _state = _ViewState.playing);
        }
      };

      _pc!.onConnectionState = (state) {
        if (!mounted) return;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          setState(() {
            _state = _ViewState.error;
            _errorMsg = 'Connection lost. Retrying...';
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _disconnect();
              _connect();
            }
          });
        }
      };

      // 4. Create SDP offer
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);

      // 5. WHEP: POST SDP offer → get SDP answer
      final res = await http
          .post(
            Uri.parse(widget.whepUrl),
            headers: {
              'Content-Type': 'application/sdp',
              'Accept': 'application/sdp',
            },
            body: offer.sdp,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('WHEP error ${res.statusCode}: ${res.body}');
      }

      // 6. Set remote SDP answer
      await _pc!.setRemoteDescription(
        RTCSessionDescription(res.body, 'answer'),
      );

      // State → playing sẽ được set khi onTrack fires
    } catch (e) {
      debugPrint('[WebRTC] Error: $e');
      if (mounted) {
        setState(() {
          _state = _ViewState.error;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _disconnect() {
    _renderer.srcObject = null;
    _pc?.close();
    _pc = null;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ViewState.connecting => _buildConnecting(),
      _ViewState.error => _buildError(),
      _ViewState.playing => _buildPlayer(),
    };
  }

  Widget _buildConnecting() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 14),
            Text('Connecting via WebRTC...',
                style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
            SizedBox(height: 4),
            Text('MediaMTX WHEP',
                style: TextStyle(color: AppTheme.textSec, fontSize: 11)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: AppTheme.textSec, size: 48),
              const SizedBox(height: 14),
              const Text('Stream unavailable',
                  style: TextStyle(
                      color: AppTheme.textPrim,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSec, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  _disconnect();
                  _connect();
                },
                icon: const Icon(Icons.refresh_rounded,
                    color: AppTheme.accent, size: 18),
                label: const Text('Retry',
                    style: TextStyle(color: AppTheme.accent)),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlayer() {
    if (!_rendererReady) return _buildConnecting();
    return RTCVideoView(
      _renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      mirror: false,
    );
  }
}

enum _ViewState { connecting, error, playing }
