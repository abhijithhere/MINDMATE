import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool isRecording = false;
  bool isProcessing = false;
  String? userId;
  String liveTranscript = "Tap the orb to speak...";
  String aiResponseText = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2)
    );
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (isProcessing) return;

    if (await Permission.microphone.request().isGranted) {
      if (isRecording) {
        await _stopAndSend();
      } else {
        await _startRecording();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required."))
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/voice_command.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      setState(() {
        isRecording = true;
        liveTranscript = "Listening...";
        aiResponseText = ""; 
        _controller.repeat(reverse: true); 
      });
    } catch (e) {
      print("Recording Error: $e");
    }
  }

  Future<void> _stopAndSend() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        isRecording = false;
        isProcessing = true;
        liveTranscript = "Processing...";
        _controller.stop();
        _controller.reset();
      });

      if (path != null && userId != null) {
        final result = await ApiService.uploadAudio(userId!, File(path));
        
        setState(() {
          isProcessing = false;
          liveTranscript = result['transcript'] ?? "Done";
          aiResponseText = result['ai_response'] ?? "";
        });
      } else {
        setState(() {
          isProcessing = false;
          liveTranscript = "Error: User ID missing or recording failed.";
        });
      }
    } catch (e) {
      print("Upload Error: $e");
      setState(() {
        isProcessing = false;
        liveTranscript = "Connection Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = isRecording ? (_controller.value * 30) : 0;
                    return Container(
                      width: 150 + scale,
                      height: 150 + scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.mintGradient,
                        boxShadow: isRecording 
                          ? [BoxShadow(color: AppTheme.kPrimaryTeal.withOpacity(0.6), blurRadius: 60, spreadRadius: 10)] 
                          : [BoxShadow(color: AppTheme.kPrimaryTeal.withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: Icon(isRecording ? Icons.mic : Icons.mic_none, size: 60, color: Colors.black),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.kCardDark,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(liveTranscript, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (aiResponseText.isNotEmpty)
                  Text(aiResponseText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}