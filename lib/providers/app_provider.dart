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

  StreamSubscription? _statusSub;
  StreamSubscription? _historySub;

  // Chống lặp thông báo
  String? _lastNotifiedAlert;
  int _lastNotifiedTs = 0;

  // ────────────────────────────────────────
  // KHỞI TẠO
  // ────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(kPrefIsLoggedIn) ?? false;
    _username = await _auth.getUsername();
    if (_loggedIn) _startStreams();
    notifyListeners();
  }

  // ────────────────────────────────────────
  // ĐĂNG NHẬP / ĐĂNG XUẤT
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
  // LUỒNG DỮ LIỆU FIREBASE (real-time)
  // ────────────────────────────────────────
  void _startStreams() {
    _stopStreams();

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

  // ────────────────────────────────────────
  // XỬ LÝ CẢNH BÁO — theo đúng thứ tự ưu tiên của Pi
  //   SOS > CRITICAL/WARNING (té ngã) > sinh hiệu
  // ────────────────────────────────────────
  void _handleAlert(SensorStatus st) {
    // SOS có mức ưu tiên cao nhất — thông báo bất kể fallDetected
    if (st.sos) {
      _notifyIfNeeded(
        key: 'SOS',
        id: 0,
        title: 'KHẨN CẤP — Nút SOS được nhấn!',
        body: 'Bệnh nhân yêu cầu trợ giúp ngay. '
            'Nhịp tim ${st.heartRate} bpm, SpO2 ${st.spo2}%.',
      );
      return;
    }

    // Té ngã đã xác nhận
    if (st.fallDetected && (st.alert == 'WARNING' || st.alert == 'CRITICAL')) {
      final crit = st.alert == 'CRITICAL';
      _notifyIfNeeded(
        key: st.alert,
        id: crit ? 1 : 2,
        title: crit ? 'TÉ NGÃ NGHIÊM TRỌNG!' : 'Phát hiện té ngã',
        body:
            'Nhịp tim ${st.heartRate} bpm · SpO2 ${st.spo2}% · ${_alertVi(st.alert)}',
      );
      return;
    }

    // Không còn cảnh báo — reset để lần sau báo lại
    _lastNotifiedAlert = null;
  }

  void _notifyIfNeeded({
    required String key,
    required int id,
    required String title,
    required String body,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isNew = key != _lastNotifiedAlert;
    final cooldownPassed = (now - _lastNotifiedTs) >= 30;

    if (isNew || cooldownPassed) {
      _lastNotifiedAlert = key;
      _lastNotifiedTs = now;
      NotificationService.instance.showAlert(id: id, title: title, body: body);
    }
  }

  // Chuyển mã cảnh báo sang tiếng Việt
  static String _alertVi(String alert) => switch (alert) {
        'SOS' => 'KHẨN CẤP',
        'CRITICAL' => 'NGUY CẤP',
        'WARNING' => 'CẢNH BÁO',
        'CHECKING' => 'ĐANG KIỂM TRA',
        'FALSE_ALARM' => 'BÁO NHẦM',
        _ => 'BÌNH THƯỜNG',
      };

  @override
  void dispose() {
    _stopStreams();
    super.dispose();
  }
}
