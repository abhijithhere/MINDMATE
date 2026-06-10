// lib/features/auth/screens/login_screen.dart
//
// FIX: After successful login, saves the real user_id (email) to
// SharedPreferences so every screen reads the correct value.
// The previous bug was likely storing 'admin' or nothing at all.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _apiService   = ApiService();

  bool _isLoading = false;
  String _error   = '';

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      final result = await _apiService.login(email, password);

      if (result.containsKey('error') || result['status'] == 'error') {
        setState(() => _error = result['error'] ?? result['detail'] ?? 'Login failed.');
        return;
      }

      // ── Save the REAL user_id (email) — NOT 'admin' ──────────────────────
      // The backend returns user_id in the response. Fall back to the email
      // the user typed if the key is missing.
      final String userId = (result['user_id'] ?? result['email'] ?? email).toString().trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id',  userId);
      await prefs.setString('username', result['username']?.toString() ?? userId);
      await prefs.setBool('is_logged_in', true);

      debugPrint('✅ Logged in as: $userId');

      if (mounted) {
        // Replace the whole stack so back-button can't return to login
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MINDMATE',
                  style: TextStyle(
                      color: AppTheme.kPrimaryTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
              const SizedBox(height: 8),
              const Text('Sign in to continue',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 48),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Password'),
              ),
              const SizedBox(height: 8),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(_error,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kPrimaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('LOGIN',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign up",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppTheme.kCardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.kPrimaryTeal),
        ),
      );
}