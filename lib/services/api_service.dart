// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/models/sensor_data.dart';

class ApiService {
  String _baseUrl = '';

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

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

  Future<bool> registerFcmToken(String token) async {
    if (_baseUrl.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/register_token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unregisterFcmToken(String token) async {
    if (_baseUrl.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/unregister_token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String get videoStreamUrl => '$_baseUrl/video';

  bool get isConfigured => _baseUrl.isNotEmpty;
}
