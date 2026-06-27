// lib/core/constants.dart

const String kPrefIsLoggedIn = 'is_logged_in';
const String kPrefUsername = 'username';
const String kPrefPassword = 'password';

// Tài khoản mặc định (lần đầu cài đặt)
const String kDefaultUsername = 'admin';
const String kDefaultPassword = '123456';

// Đường dẫn Firebase RTDB — khớp với node mà Raspberry Pi ghi vào
const String kDbStatus = 'fall_detection/status';
const String kDbHistory = 'fall_detection/history';
const String kDbEvents = 'fall_detection/fall_events';

// Ngưỡng cảnh báo sinh hiệu — KHỚP với Pi (HR_LOW=50, HR_HIGH=120, SPO2=90)
const int kHrLow = 50;
const int kHrHigh = 120;
const int kSpo2Critical = 90;
