// lib/models/sensor_data.dart
//
// Mô hình dữ liệu khớp chính xác với endpoint /status của Raspberry Pi:
//   { heart_rate, spo2, steps, fall_flag, sos, fall_detected, alert, state, timestamp }

class SensorStatus {
  final int heartRate;
  final int spo2;
  final int steps;
  final bool fallFlag; // cờ gia tốc MPU6050 (cú sốc)
  final bool sos; // nút khẩn cấp
  final bool fallDetected; // kết quả cuối: đã xác nhận té ngã
  final String alert; // NORMAL/CHECKING/WARNING/CRITICAL/SOS/FALSE_ALARM
  final String state; // IDLE/PENDING/FALL_CONFIRMED/FALSE_ALARM
  final int timestamp;

  const SensorStatus({
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.fallFlag,
    required this.sos,
    required this.fallDetected,
    required this.alert,
    required this.state,
    required this.timestamp,
  });

  factory SensorStatus.fromJson(Map<String, dynamic> j) => SensorStatus(
        heartRate: (j['heart_rate'] as num?)?.toInt() ?? 0,
        spo2: (j['spo2'] as num?)?.toInt() ?? 0,
        steps: (j['steps'] as num?)?.toInt() ?? 0,
        fallFlag: j['fall_flag'] as bool? ?? false,
        sos: j['sos'] as bool? ?? false,
        fallDetected: j['fall_detected'] as bool? ?? false,
        alert: j['alert'] as String? ?? 'NORMAL',
        state: j['state'] as String? ?? 'IDLE',
        timestamp: (j['timestamp'] as num?)?.toInt() ?? 0,
      );

  static SensorStatus empty() => const SensorStatus(
        heartRate: 0,
        spo2: 0,
        steps: 0,
        fallFlag: false,
        sos: false,
        fallDetected: false,
        alert: 'NORMAL',
        state: 'IDLE',
        timestamp: 0,
      );
}

class SensorHistory {
  final List<int> heartRates;
  final List<int> spo2s;
  final List<int> timestamps;

  const SensorHistory({
    required this.heartRates,
    required this.spo2s,
    required this.timestamps,
  });

  factory SensorHistory.fromJson(Map<String, dynamic> j) {
    List<int> toList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .where((e) => e != null)
            .map((e) => (e as num).toInt())
            .toList();
      }
      // Firebase RTDB trả về Map khi mảng có khoảng trống (null gaps)
      if (raw is Map) {
        final entries = raw.entries.where((e) => e.value != null).toList()
          ..sort((a, b) => int.parse(a.key.toString())
              .compareTo(int.parse(b.key.toString())));
        return entries.map((e) => (e.value as num).toInt()).toList();
      }
      return [];
    }

    return SensorHistory(
      heartRates: toList(j['heart_rate']),
      spo2s: toList(j['spo2']),
      timestamps: toList(j['timestamps']),
    );
  }

  static SensorHistory empty() =>
      const SensorHistory(heartRates: [], spo2s: [], timestamps: []);

  int get length => heartRates.length;
}
