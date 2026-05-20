// lib/providers/app_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── Auth ──
  bool _loggedIn = false;
  String _username = '';
  bool get loggedIn => _loggedIn;
  String get username => _username;

  // ── Connection ──
  bool _connected = false;
  bool get connected => _connected;

  // ── Sensor data ──
  SensorStatus _status = SensorStatus.empty();
  SensorHistory _history = SensorHistory.empty();

  SensorStatus get status => _status;
  SensorHistory get history => _history;
  String get baseUrl => _api.baseUrl;
  String get videoUrl => _api.videoStreamUrl;

  // ── Polling ──
  Timer? _statusTimer;
  Timer? _historyTimer;

  // ── Alert dedup: tránh spam notification ──
  String? _lastNotifiedAlert; // alert string lần cuối đã notify
  int _lastNotifiedTs = 0; // timestamp lần cuối notify

  // ────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(kPrefIsLoggedIn) ?? false;
    _username = prefs.getString(kPrefUsername) ?? '';
    final saved = prefs.getString(kPrefBaseUrl) ?? '';
    if (saved.isNotEmpty) _api.baseUrl = saved;
    if (_loggedIn) _startPolling();
    notifyListeners();
  }

  // ────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────
  Future<bool> login(String username, String password, String serverUrl) async {
    if (username != kAdminUsername || password != kAdminPassword) return false;

    _api.baseUrl = serverUrl;
    final st = await _api.fetchStatus();
    if (st == null) return false;

    _loggedIn = true;
    _username = username;
    _status = st;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefIsLoggedIn, true);
    await prefs.setString(kPrefUsername, username);
    await prefs.setString(kPrefBaseUrl, serverUrl);

    _startPolling();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _stopPolling();
    await NotificationService.instance.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefIsLoggedIn, false);
    _loggedIn = false;
    _username = '';
    _connected = false;
    _status = SensorStatus.empty();
    _history = SensorHistory.empty();
    _lastNotifiedAlert = null;
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    _api.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefBaseUrl, url);
    notifyListeners();
  }

  // ────────────────────────────────────────
  // POLLING
  // ────────────────────────────────────────
  void _startPolling() {
    _statusTimer?.cancel();
    _historyTimer?.cancel();
    _statusTimer = Timer.periodic(kPollInterval, (_) => _pollStatus());
    _historyTimer = Timer.periodic(kHistoryInterval, (_) => _pollHistory());
    _pollStatus();
    _pollHistory();
  }

  void _stopPolling() {
    _statusTimer?.cancel();
    _historyTimer?.cancel();
  }

  Future<void> _pollStatus() async {
    final st = await _api.fetchStatus();
    if (st == null) {
      _connected = false;
    } else {
      _connected = true;

      // ── Trigger local notification ──
      if (st.fallDetected &&
          (st.alert == 'WARNING' || st.alert == 'CRITICAL')) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        // Notify nếu: alert mới khác lần trước HOẶC đã qua 30s cooldown
        final newAlert = st.alert != _lastNotifiedAlert;
        final cooldownOk = (now - _lastNotifiedTs) >= 30;

        if (newAlert || cooldownOk) {
          _lastNotifiedAlert = st.alert;
          _lastNotifiedTs = now;

          final isCritical = st.alert == 'CRITICAL';
          NotificationService.instance.showAlert(
            id: isCritical ? 1 : 2,
            title:
                isCritical ? '🚨 TÉ NGÃ NGHIÊM TRỌNG!' : '⚠️ Phát hiện té ngã',
            body:
                'HR: ${st.heartRate} bpm  |  SpO2: ${st.spo2}%  |  ${st.alert}',
          );
        }
      } else if (!st.fallDetected) {
        // Reset dedup khi trở về bình thường
        _lastNotifiedAlert = null;
      }

      _status = st;
    }
    notifyListeners();
  }

  Future<void> _pollHistory() async {
    final h = await _api.fetchHistory();
    if (h != null) {
      _history = h;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
