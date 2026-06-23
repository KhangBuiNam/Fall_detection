// lib/providers/app_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/sensor_data.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;
  final FirebaseService _fb = FirebaseService.instance;

  bool _loggedIn = false;
  bool _connected = false;
  String _username = '';

  SensorStatus _status = SensorStatus.empty();
  SensorHistory _history = SensorHistory.empty();

  bool get loggedIn => _loggedIn;
  bool get connected => _connected;
  String get username => _username;

  SensorStatus get status => _status;
  SensorHistory get history => _history;

  // Firebase stream subscriptions
  StreamSubscription? _statusSub;
  StreamSubscription? _historySub;

  // Alert dedup
  String? _lastNotifiedAlert;
  int _lastNotifiedTs = 0;

  // ────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(kPrefIsLoggedIn) ?? false;
    _username = await _auth.getUsername();
    if (_loggedIn) _startStreams();
    notifyListeners();
  }

  // ────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    final ok = await _auth.checkCredentials(username, password);
    if (!ok) return false;

    _loggedIn = true;
    _username = username;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefIsLoggedIn, true);

    _startStreams();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _stopStreams();
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

  Future<void> refreshUsername() async {
    _username = await _auth.getUsername();
    notifyListeners();
  }

  // ────────────────────────────────────────
  // FIREBASE STREAMS
  // ────────────────────────────────────────
  void _startStreams() {
    _stopStreams();

    // Status stream — real-time
    _statusSub = _fb.statusStream.listen(
      (status) {
        _connected = true;
        _handleAlert(status);
        _status = status;
        notifyListeners();
      },
      onError: (_) {
        _connected = false;
        notifyListeners();
      },
    );

    // History stream — cập nhật khi Pi push mới
    _historySub = _fb.historyStream.listen(
      (history) {
        _history = history;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _stopStreams() {
    _statusSub?.cancel();
    _historySub?.cancel();
    _statusSub = null;
    _historySub = null;
  }

  void _handleAlert(SensorStatus st) {
    if (!st.fallDetected) {
      _lastNotifiedAlert = null;
      return;
    }
    if (st.alert != 'WARNING' && st.alert != 'CRITICAL') return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newAlert = st.alert != _lastNotifiedAlert;
    final cooldown = (now - _lastNotifiedTs) >= 30;

    if (newAlert || cooldown) {
      _lastNotifiedAlert = st.alert;
      _lastNotifiedTs = now;
      final crit = st.alert == 'CRITICAL';
      NotificationService.instance.showAlert(
        id: crit ? 1 : 2,
        title: crit ? '🚨 TÉ NGÃ NGHIÊM TRỌNG!' : '⚠️ Phát hiện té ngã',
        body: 'HR: ${st.heartRate} bpm | SpO2: ${st.spo2}% | ${st.alert}',
      );
    }
  }

  @override
  void dispose() {
    _stopStreams();
    super.dispose();
  }
}
