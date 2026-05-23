// lib/core/constants.dart

const String kPrefBaseUrl = 'base_url';
const String kPrefIsLoggedIn = 'is_logged_in';
const String kPrefUsername = 'username';
const String kPrefPassword = 'password'; // lưu password đã hash

// Default credentials — chỉ dùng lần đầu cài app, sau đó đọc từ SharedPreferences
const String kDefaultUsername = 'caregiver';
const String kDefaultPassword = 'falldetect2024';

// Polling interval
const Duration kPollInterval = Duration(seconds: 2);
const Duration kHistoryInterval = Duration(seconds: 10);
