// lib/screens/login_screen.dart
// Chỉ username + password — không cần nhập URL nào cả
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
    if (!ok) setState(() => _error = 'Invalid username or password.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2A), Color(0xFF0A0E1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C6FF).withOpacity(0.4),
                                blurRadius: 28,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.health_and_safety_rounded,
                              size: 46, color: Colors.white),
                        ),
                        const SizedBox(height: 22),
                        Text('CareWatch',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    color: AppTheme.textPrim,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3)),
                        const SizedBox(height: 6),
                        Text('Patient Monitoring System',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSec)),
                        const SizedBox(height: 40),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.accent.withOpacity(0.15)),
                          ),
                          child: Column(children: [
                            _field(_userCtrl, 'Username', Icons.person_rounded,
                                hint: 'caregiver',
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Enter username'
                                    : null),
                            const SizedBox(height: 16),
                            _field(_passCtrl, 'Password', Icons.lock_rounded,
                                obscure: _obscure,
                                suffix: IconButton(
                                    icon: Icon(
                                        _obscure
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: AppTheme.textSec,
                                        size: 20),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure)),
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Enter password'
                                    : null),

                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.critical.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            AppTheme.critical.withOpacity(0.3)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline,
                                        color: AppTheme.critical, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(_error!,
                                            style: const TextStyle(
                                                color: AppTheme.critical,
                                                fontSize: 12))),
                                  ])),
                            ],
                            const SizedBox(height: 24),

                            // Sign in button
                            SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF00C6FF),
                                        Color(0xFF0072FF)
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                            color: const Color(0xFF00C6FF)
                                                .withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6))
                                      ],
                                    ),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14))),
                                        onPressed: _loading ? null : _submit,
                                        child: _loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5))
                                            : const Text('Sign In',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white))))),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        // Firebase badge
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_done_rounded,
                                  color: AppTheme.normal.withOpacity(0.7),
                                  size: 14),
                              const SizedBox(width: 6),
                              Text('Powered by Firebase Realtime Database',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSec)),
                            ]),
                      ],
                    ),
                  ),
                ),
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
              labelStyle:
                  const TextStyle(color: AppTheme.textSec, fontSize: 13),
              prefixIcon: Icon(icon, color: AppTheme.accent, size: 20),
              suffixIcon: suffix,
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppTheme.accent.withOpacity(0.7), width: 1.5)),
              errorStyle:
                  const TextStyle(color: AppTheme.critical, fontSize: 11),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
          validator: validator);
}
