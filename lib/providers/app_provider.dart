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
  bool _loading = false;

  SensorStatus get status => _status;
  SensorHistory get history => _history;
  bool get loading => _loading;
  String get baseUrl => _api.baseUrl;
  String get videoUrl => _api.videoStreamUrl;

  // ── Polling timers ──
  Timer? _statusTimer;
  Timer? _historyTimer;

  // ── Alerts ──
  String? _lastAlert;

  // ─────────────────────────────────
  // INIT
  // ─────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(kPrefIsLoggedIn) ?? false;
    _username = prefs.getString(kPrefUsername) ?? '';
    final savedUrl = prefs.getString(kPrefBaseUrl) ?? '';
    if (savedUrl.isNotEmpty) _api.baseUrl = savedUrl;

    if (_loggedIn) _startPolling();
    notifyListeners();
  }

  // ─────────────────────────────────
  // AUTH
  // ─────────────────────────────────

  Future<bool> login(String username, String password, String serverUrl) async {
    if (username != kAdminUsername || password != kAdminPassword) {
      return false;
    }

    _api.baseUrl = serverUrl;

    // Test connection
    final st = await _api.fetchStatus();
    if (st == null) return false; // server unreachable

    _loggedIn = true;
    _username = username;
    _status = st;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefIsLoggedIn, true);
    await prefs.setString(kPrefUsername, username);
    await prefs.setString(kPrefBaseUrl, serverUrl);

    // Register FCM token to server
    final token = NotificationService.instance.fcmToken;
    if (token != null) {
      await _api.registerFcmToken(token);
      await prefs.setString(kPrefFcmToken, token);
    }

    _startPolling();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _stopPolling();

    // Unregister FCM token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kPrefFcmToken);
    if (token != null) await _api.unregisterFcmToken(token);

    await prefs.setBool(kPrefIsLoggedIn, false);
    await prefs.remove(kPrefFcmToken);

    _loggedIn = false;
    _username = '';
    _connected = false;
    _status = SensorStatus.empty();
    _history = SensorHistory.empty();
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    _api.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefBaseUrl, url);
    notifyListeners();
  }

  // ─────────────────────────────────
  // POLLING
  // ─────────────────────────────────

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

      // Trigger local notification if fall newly detected
      if (st.fallDetected &&
          (_lastAlert == null || _lastAlert != st.alert) &&
          (st.alert == 'WARNING' || st.alert == 'CRITICAL')) {
        _lastAlert = st.alert;
        NotificationService.instance.showLocalNotification(
          title:
              st.alert == 'CRITICAL' ? '🚨 CRITICAL FALL!' : '⚠️ Fall Warning',
          body: 'HR: ${st.heartRate} bpm | SpO2: ${st.spo2}% | ${st.alert}',
        );
      } else if (!st.fallDetected) {
        _lastAlert = null;
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
