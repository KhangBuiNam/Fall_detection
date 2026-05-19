// lib/core/constants.dart

const String kPrefBaseUrl = 'base_url';
const String kPrefIsLoggedIn = 'is_logged_in';
const String kPrefUsername = 'username';
const String kPrefFcmToken = 'fcm_token';

// Credentials (hardcoded cho caregiver — đổi tuỳ ý)
const String kAdminUsername = 'caregiver';
const String kAdminPassword = 'falldetect2024';

// Polling interval
const Duration kPollInterval = Duration(seconds: 2);
const Duration kHistoryInterval = Duration(seconds: 10);

// Alert colors
const int kColorCritical = 0xFFFF3B30;
const int kColorWarning = 0xFFFF9500;
const int kColorNormal = 0xFF30D158;
const int kColorChecking = 0xFF64D2FF;
const int kColorFalseAlarm = 0xFFAC8E68;
