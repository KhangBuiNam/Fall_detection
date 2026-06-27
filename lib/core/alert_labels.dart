// lib/core/alert_labels.dart
//
// Tập trung việc chuyển mã trạng thái (Pi gửi bằng tiếng Anh) sang nhãn
// tiếng Việt và màu hiển thị — để mọi màn hình dùng chung, tránh lặp code.

import 'package:flutter/material.dart';
import 'app_theme.dart';

class AlertLabels {
  // Nhãn cảnh báo tiếng Việt
  static String alertText(String alert) => switch (alert) {
        'SOS' => 'KHẨN CẤP',
        'CRITICAL' => 'NGUY CẤP',
        'WARNING' => 'CẢNH BÁO',
        'CHECKING' => 'ĐANG KIỂM TRA',
        'FALSE_ALARM' => 'BÁO NHẦM',
        _ => 'BÌNH THƯỜNG',
      };

  // Màu theo cảnh báo
  static Color alertColor(String alert) => switch (alert) {
        'SOS' => const Color(0xFFE5398B), // hồng đậm
        'CRITICAL' => AppTheme.critical,
        'WARNING' => AppTheme.warning,
        'CHECKING' => const Color(0xFF4BA3C7),
        'FALSE_ALARM' => const Color(0xFF8C7A5B),
        _ => AppTheme.normal,
      };

  // Nhãn trạng thái hệ thống tiếng Việt
  static String stateText(String state) => switch (state) {
        'FALL_CONFIRMED' => 'Đã xác nhận té ngã',
        'PENDING' => 'Đang kiểm tra',
        'FALSE_ALARM' => 'Báo nhầm',
        _ => 'Bình thường',
      };

  // Icon theo trạng thái
  static IconData stateIcon(String state) => switch (state) {
        'FALL_CONFIRMED' => Icons.personal_injury_outlined,
        'PENDING' => Icons.hourglass_top_rounded,
        'FALSE_ALARM' => Icons.check_circle_outline_rounded,
        _ => Icons.person_outline_rounded,
      };
}
