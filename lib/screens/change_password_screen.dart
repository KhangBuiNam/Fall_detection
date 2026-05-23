// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill username hiện tại
    AuthService.instance.getUsername().then((u) {
      if (mounted) _userCtrl.text = u;
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    // Xác nhận password hiện tại
    final currentOk =
        await AuthService.instance.verifyCurrentPassword(_currentCtrl.text);

    if (!currentOk) {
      setState(() {
        _saving = false;
        _error = 'Current password is incorrect.';
      });
      return;
    }

    // Lưu credentials mới
    await AuthService.instance.updateCredentials(
      newUsername: _userCtrl.text.trim(),
      newPassword: _newCtrl.text,
    );

    // Cập nhật display name trong provider
    if (mounted) {
      await context.read<AppProvider>().refreshUsername();
      setState(() => _saving = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.normal.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.normal, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Credentials Updated!',
                style: TextStyle(
                    color: AppTheme.textPrim,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Your username and password have been saved.\nThey will be required on next login.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSec, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to settings
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.normal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.accent, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Enter your current password to confirm, then set the new credentials.',
                        style: TextStyle(color: AppTheme.textSec, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section: New credentials ──
              _sectionLabel('New Credentials'),
              const SizedBox(height: 12),
              _buildField(
                controller: _userCtrl,
                label: 'Username',
                icon: Icons.person_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter username';
                  if (v.trim().length < 3) return 'Min 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _newCtrl,
                label: 'New Password',
                icon: Icons.lock_rounded,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter new password';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Section: Verify identity ──
              _sectionLabel('Confirm Your Identity'),
              const SizedBox(height: 12),
              _buildField(
                controller: _currentCtrl,
                label: 'Current Password',
                icon: Icons.verified_user_rounded,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Enter current password' : null,
              ),

              // ── Error ──
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.critical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.critical.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.critical, size: 18),
                      const SizedBox(width: 8),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.critical, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: AppTheme.textSec,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrim, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSec, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppTheme.textSec,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: AppTheme.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.accent.withOpacity(0.7), width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.critical, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }
}
