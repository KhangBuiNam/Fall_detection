// lib/screens/chart_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../providers/app_provider.dart';
import '../models/sensor_data.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biểu đồ sinh hiệu')),
      body: Consumer<AppProvider>(
        builder: (_, prov, __) {
          final h = prov.history;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _LiveBadge(status: prov.status),
              const SizedBox(height: 16),
              _VitalChart(
                title: 'Nhịp tim',
                unit: 'bpm',
                icon: Icons.favorite_outline_rounded,
                color: AppTheme.hrLine,
                history: h,
                getValue: (h, i) => h.heartRates[i].toDouble(),
                normalMin: kHrLow.toDouble(), // 50 — khớp Pi
                normalMax: kHrHigh.toDouble(), // 120 — khớp Pi
              ),
              const SizedBox(height: 16),
              _VitalChart(
                title: 'SpO2',
                unit: '%',
                icon: Icons.water_drop_outlined,
                color: AppTheme.spo2Line,
                history: h,
                getValue: (h, i) => h.spo2s[i].toDouble(),
                normalMin: kSpo2Critical.toDouble(), // 90 — khớp Pi
                normalMax: 100,
                minY: 80,
                maxY: 101,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final SensorStatus status;
  const _LiveBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.normal),
          ),
          const SizedBox(width: 10),
          const Text('Đồng bộ real-time qua Firebase',
              style: TextStyle(color: AppTheme.textSec, fontSize: 12)),
          const Spacer(),
          Text('${status.heartRate} bpm · ${status.spo2}%',
              style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VitalChart extends StatelessWidget {
  final String title, unit;
  final IconData icon;
  final Color color;
  final SensorHistory history;
  final double Function(SensorHistory, int) getValue;
  final double normalMin, normalMax;
  final double? minY, maxY;

  const _VitalChart({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.history,
    required this.getValue,
    required this.normalMin,
    required this.normalMax,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), getValue(history, i)));
    }

    final curVal = spots.isNotEmpty ? spots.last.y : 0.0;
    final isWarning = curVal > 0 && (curVal < normalMin || curVal > normalMax);

    final chartMin = minY ?? (normalMin - normalMin * 0.15);
    final chartMax = maxY ?? (normalMax + normalMax * 0.1);
    final lineColor = isWarning ? AppTheme.critical : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? AppTheme.critical.withOpacity(0.4)
              : color.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: lineColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrim,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const Spacer(),
              if (isWarning)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.critical.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('BẤT THƯỜNG',
                      style: TextStyle(
                          color: AppTheme.critical,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                )
              else
                Text(
                  curVal > 0
                      ? '${curVal.toStringAsFixed(0)} $unit'
                      : '-- $unit',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          if (isWarning) ...[
            const SizedBox(height: 4),
            Text(
              '${curVal.toStringAsFixed(0)} $unit · Bình thường: '
              '${normalMin.toInt()}–${normalMax.toInt()}',
              style: const TextStyle(color: AppTheme.critical, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: spots.isEmpty
                ? const Center(
                    child: Text('Chưa có dữ liệu',
                        style:
                            TextStyle(color: AppTheme.textSec, fontSize: 13)),
                  )
                : LineChart(
                    LineChartData(
                      minY: chartMin,
                      maxY: chartMax,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.textSec.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (val, _) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(
                                  color: AppTheme.textSec, fontSize: 10),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      rangeAnnotations: RangeAnnotations(
                        horizontalRangeAnnotations: [
                          HorizontalRangeAnnotation(
                            y1: normalMin,
                            y2: normalMax,
                            color: color.withOpacity(0.06),
                          ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: lineColor,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, _) => spot.x == spots.last.x,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: lineColor,
                              strokeWidth: 0,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                lineColor.withOpacity(0.18),
                                lineColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${spots.length} điểm',
                  style:
                      const TextStyle(color: AppTheme.textSec, fontSize: 11)),
              Text(
                'Bình thường ${normalMin.toInt()}–${normalMax.toInt()} $unit',
                style: const TextStyle(color: AppTheme.textSec, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
