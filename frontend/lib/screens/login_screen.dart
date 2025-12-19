import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; 
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true; 
  bool isLoading = false;

  Future<void> _authenticate() async {
    setState(() => isLoading = true);
    
    final endpoint = isLogin ? "login" : "signup";
    // Using 10.0.2.2 for Android Emulator access to localhost
    final url = Uri.parse('http://10.0.2.2:8000/$endpoint');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": _usernameController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (isLogin) {
          // LOGIN SUCCESS
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', _usernameController.text);
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const HomeScreen())
            );
          }
        } else {
          // SIGNUP SUCCESS
          setState(() {
            isLogin = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account created! Please login.")),
            );
          });
        }
      } else {
        final data = json.decode(response.body);
        _showError(data['detail'] ?? "Authentication failed");
      }
    } catch (e) {
      _showError("Connection Error. Is backend running?");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom Colors
    const Color kPrimaryTeal = Color(0xFF00E5FF); 
    const Color kBackgroundDark = Color(0xFF121212);

    return Scaffold(
      backgroundColor: kBackgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: kPrimaryTeal),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Welcome Back" : "Create Account",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryTeal)),
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimaryTeal)),
                  prefixIcon: Icon(Icons.key, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryTeal),
                  onPressed: isLoading ? null : _authenticate,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Need an account? Sign Up" : "Have an account? Login", style: TextStyle(color: kPrimaryTeal)),
              )
            ],
          ),
        ),
      ),
    );
  }
}