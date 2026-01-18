import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../main.dart'; // To navigate to MainLayout

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool isLoading = false;
  String errorMessage = "";

  // 🔵 LOGIN FUNCTION
  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": _userController.text.trim(),
          "password": _passController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // ✅ Login Success: Save User ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _userController.text.trim());
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const MainLayout())
          );
        }
      } else {
        setState(() => errorMessage = data['detail'] ?? "Login failed");
      }
    } catch (e) {
      setState(() => errorMessage = "Connection Error. Check Backend.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🟢 SIGNUP FUNCTION (New!)
  Future<void> _signup() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final url = Uri.parse('${ApiConstants.baseUrl}/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": _userController.text.trim(),
          "password": _passController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Auto Login after Signup
        _login(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created! Logging in...")),
        );
      } else {
        setState(() => errorMessage = data['detail'] ?? "Signup failed");
      }
    } catch (e) {
      setState(() => errorMessage = "Connection Error. Check Backend.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, size: 80, color: AppTheme.kPrimaryTeal),
              const SizedBox(height: 20),
              const Text("MindMate", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // Username Input
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: AppTheme.kCardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: AppTheme.kCardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),
                ),

              if (isLoading)
                const CircularProgressIndicator(color: AppTheme.kPrimaryTeal)
              else
                Column(
                  children: [
                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kPrimaryTeal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _login,
                        child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // SIGNUP BUTTON (The Missing Piece!)
                    TextButton(
                      onPressed: _signup,
                      child: const Text("New User? Create Account", style: TextStyle(color: AppTheme.kTextGrey)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}