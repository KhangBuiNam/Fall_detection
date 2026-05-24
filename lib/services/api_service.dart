// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  String _baseUrl = ''; // Flask server (Tailscale IP:5000)
  String _mediaUrl = ''; // MediaMTX server (Tailscale IP:8889)

  // ── Flask base URL (cảm biến / status) ──
  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // ── MediaMTX base URL (WebRTC stream) ──
  String get mediaUrl => _mediaUrl;
  set mediaUrl(String url) {
    _mediaUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // WHEP endpoint — Flutter gọi để lấy SDP answer
  // Format: http://<tailscale-ip>:8889/live/whep
  String get whepUrl => '$_mediaUrl/live/whep';

  bool get isConfigured => _baseUrl.isNotEmpty;
  bool get isMediaConfigured => _mediaUrl.isNotEmpty;

  Future<SensorStatus?> fetchStatus() async {
    if (_baseUrl.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return SensorStatus.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  Future<SensorHistory?> fetchHistory() async {
    if (_baseUrl.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/history'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return SensorHistory.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }
}
