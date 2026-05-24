// lib/core/constants.dart

const String kPrefBaseUrl = 'base_url';
const String kPrefMediaUrl = 'media_url'; // MediaMTX Tailscale URL
const String kPrefIsLoggedIn = 'is_logged_in';
const String kPrefUsername = 'username';
const String kPrefPassword = 'password';

// Default credentials
const String kDefaultUsername = 'caregiver';
const String kDefaultPassword = 'falldetect2024';

// Polling interval
const Duration kPollInterval = Duration(seconds: 2);
const Duration kHistoryInterval = Duration(seconds: 10);
