// lib/services/auth_service.dart
//
// Quản lý tài khoản — lưu trong SharedPreferences.
// Lần đầu cài đặt dùng tài khoản mặc định, sau đó người dùng đổi trong Cài đặt.

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kPrefUsername) ?? kDefaultUsername;
  }

  Future<String> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kPrefPassword) ?? kDefaultPassword;
  }

  Future<bool> checkCredentials(String username, String password) async {
    final savedUser = await getUsername();
    final savedPass = await _getPassword();
    return username == savedUser && password == savedPass;
  }

  Future<void> updateCredentials({
    required String newUsername,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefUsername, newUsername);
    await prefs.setString(kPrefPassword, newPassword);
  }

  Future<void> updatePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefPassword, newPassword);
  }

  Future<bool> verifyCurrentPassword(String password) async {
    final saved = await _getPassword();
    return password == saved;
  }
}
