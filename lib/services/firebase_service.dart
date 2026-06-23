// lib/services/firebase_service.dart
//
// Đọc dữ liệu từ Firebase Realtime Database.
// Pi write vào /fall_detection/status và /fall_detection/history
// Flutter lắng nghe stream real-time — không cần poll HTTP.

import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  final _db = FirebaseDatabase.instance;

  // ── Stream trạng thái hiện tại (real-time) ──
  Stream<SensorStatus> get statusStream {
    return _db.ref('fall_detection/status').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return SensorStatus.empty();
      try {
        final map = Map<String, dynamic>.from(data as Map);
        return SensorStatus.fromJson(map);
      } catch (_) {
        return SensorStatus.empty();
      }
    });
  }

  // ── Lấy history 1 lần (không cần real-time) ──
  Future<SensorHistory> fetchHistory() async {
    try {
      final snap = await _db.ref('fall_detection/history').get();
      if (!snap.exists || snap.value == null) {
        return SensorHistory.empty();
      }
      final map = Map<String, dynamic>.from(snap.value as Map);
      return SensorHistory.fromJson(map);
    } catch (_) {
      return SensorHistory.empty();
    }
  }

  // ── Stream history (cập nhật mỗi khi Pi push mới) ──
  Stream<SensorHistory> get historyStream {
    return _db.ref('fall_detection/history').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return SensorHistory.empty();
      try {
        final map = Map<String, dynamic>.from(data as Map);
        return SensorHistory.fromJson(map);
      } catch (_) {
        return SensorHistory.empty();
      }
    });
  }
}
