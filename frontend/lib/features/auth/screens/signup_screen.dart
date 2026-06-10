import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart'; // Ensure record: ^5.1.0 is in pubspec
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final AudioRecorder _recorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      _showMsg("Please fill in all fields");
      return;
    }
    if (_audioPath == null) {
      _showMsg("Please record your voice to complete enrollment");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      bool success = await apiService.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _audioPath!
      );

      if (success) {
        _showMsg("Account & Voice Profile Created!", isError: false);
        if (mounted) Navigator.pop(context); 
      } else {
        _showMsg("Registration failed. Try again.");
      }
    } catch (e) {
      _showMsg("Connection Error: Is the server running?");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.redAccent : Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.person_add_outlined, size: 70, color: AppTheme.kPrimaryTeal),
            const SizedBox(height: 20),
            const Text("JOIN MINDMATE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            _buildField(_nameController, "Full Name", Icons.badge_outlined),
            const SizedBox(height: 20),
            _buildField(_emailController, "Gmail ID", Icons.email_outlined),
            const SizedBox(height: 20),
            _buildField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
            const SizedBox(height: 30),
            
            // --- VOICE ENROLLMENT SECTION ---
            const Text("VOICE ENROLLMENT", style: TextStyle(color: AppTheme.kPrimaryTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onLongPress: () async {
                if (await _recorder.hasPermission()) {
                  final dir = await getApplicationDocumentsDirectory();
                  final path = '${dir.path}/signup_temp.wav';
                  await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
                  setState(() { _isRecording = true; _audioPath = null; });
                }
              },
              onLongPressEnd: (_) async {
                final path = await _recorder.stop();
                setState(() { _isRecording = false; _audioPath = path; });
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: _isRecording ? Colors.redAccent : (_audioPath != null ? Colors.green : AppTheme.kPrimaryTeal.withOpacity(0.2)),
                    child: Icon(_isRecording ? Icons.mic : (_audioPath != null ? Icons.check : Icons.mic_none), color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(_isRecording ? "Listening..." : (_audioPath != null ? "Voice Recorded" : "Hold to Record Voice"), style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            // ---------------------------------

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextField(controller: controller, obscureText: isObscure, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.kPrimaryTeal),
        filled: true, fillColor: AppTheme.kCardDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}