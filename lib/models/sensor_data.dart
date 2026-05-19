// lib/models/sensor_data.dart

class SensorStatus {
  final int heartRate;
  final int spo2;
  final int event;
  final bool fallDetected;
  final String alert;
  final String state;
  final int timestamp;

  const SensorStatus({
    required this.heartRate,
    required this.spo2,
    required this.event,
    required this.fallDetected,
    required this.alert,
    required this.state,
    required this.timestamp,
  });

  factory SensorStatus.fromJson(Map<String, dynamic> j) => SensorStatus(
        heartRate: (j['heart_rate'] as num?)?.toInt() ?? 0,
        spo2: (j['spo2'] as num?)?.toInt() ?? 0,
        event: (j['event'] as num?)?.toInt() ?? 0,
        fallDetected: j['fall_detected'] as bool? ?? false,
        alert: j['alert'] as String? ?? 'NORMAL',
        state: j['state'] as String? ?? 'IDLE',
        timestamp: (j['timestamp'] as num?)?.toInt() ?? 0,
      );

  static SensorStatus empty() => const SensorStatus(
        heartRate: 0,
        spo2: 0,
        event: 0,
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
    List<int> toIntList(dynamic raw) =>
        (raw as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
    return SensorHistory(
      heartRates: toIntList(j['heart_rate']),
      spo2s: toIntList(j['spo2']),
      timestamps: toIntList(j['timestamps']),
    );
  }

  static SensorHistory empty() =>
      const SensorHistory(heartRates: [], spo2s: [], timestamps: []);

  int get length => heartRates.length;
}
