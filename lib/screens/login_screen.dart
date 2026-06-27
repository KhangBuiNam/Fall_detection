// lib/screens/login_screen.dart
// Đăng nhập bằng tài khoản — dữ liệu lấy real-time từ Firebase, không cần nhập URL.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await context.read<AppProvider>().login(
          _userCtrl.text.trim(),
          _passCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = 'Sai tên đăng nhập hoặc mật khẩu.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo đơn giản, không glow neon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withOpacity(0.15),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        size: 40, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 20),
                  const Text('Hệ thống giám sát té ngã',
                      style: TextStyle(
                          color: AppTheme.textPrim,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Giám sát sức khỏe người bệnh, người cao tuổi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSec, fontSize: 13)),
                  const SizedBox(height: 36),

                  // Thẻ đăng nhập
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppTheme.accent.withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        _field(_userCtrl, 'Tên đăng nhập',
                            Icons.person_outline_rounded,
                            hint: 'admin',
                            validator: (v) => v?.isEmpty ?? true
                                ? 'Nhập tên đăng nhập'
                                : null),
                        const SizedBox(height: 16),
                        _field(
                            _passCtrl, 'Mật khẩu', Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textSec,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Nhập mật khẩu' : null),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.critical.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.critical.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppTheme.critical, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AppTheme.critical,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Text('Đăng nhập',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_done_outlined,
                          color: AppTheme.normal.withOpacity(0.7), size: 14),
                      const SizedBox(width: 6),
                      const Text('Dữ liệu đồng bộ qua Firebase',
                          style:
                              TextStyle(color: AppTheme.textSec, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {String? hint,
          bool obscure = false,
          Widget? suffix,
          String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.textPrim, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSec, fontSize: 13),
          labelStyle: const TextStyle(color: AppTheme.textSec, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppTheme.accent.withOpacity(0.6), width: 1.5),
          ),
          errorStyle: const TextStyle(color: AppTheme.critical, fontSize: 11),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      );
}
