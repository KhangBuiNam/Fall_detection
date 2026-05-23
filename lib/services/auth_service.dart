// lib/services/auth_service.dart
//
// Quản lý credentials — lưu trong SharedPreferences.
// Lần đầu cài app dùng default, sau đó user có thể đổi trong Settings.

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // ── Lấy username hiện tại (đọc từ prefs, fallback default) ──
  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kPrefUsername) ?? kDefaultUsername;
  }

  // ── Lấy password hiện tại ──
  Future<String> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kPrefPassword) ?? kDefaultPassword;
  }

  // ── Kiểm tra login ──
  Future<bool> checkCredentials(String username, String password) async {
    final savedUser = await getUsername();
    final savedPass = await _getPassword();
    return username == savedUser && password == savedPass;
  }

  // ── Đổi username + password ──
  Future<void> updateCredentials({
    required String newUsername,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefUsername, newUsername);
    await prefs.setString(kPrefPassword, newPassword);
  }

  // ── Chỉ đổi password ──
  Future<void> updatePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefPassword, newPassword);
  }

  // ── Xác nhận password hiện tại trước khi đổi ──
  Future<bool> verifyCurrentPassword(String password) async {
    final saved = await _getPassword();
    return password == saved;
  }
}
