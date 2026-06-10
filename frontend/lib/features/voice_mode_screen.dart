// lib/features/voice_mode_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class VoiceModeScreen extends StatefulWidget {
  final String? userId;
  const VoiceModeScreen({super.key, this.userId});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();

  bool _isOn = false;
  bool isProcessing = false;
  String? userId;
  String liveTranscript = "Tap the orb to speak...";
  String aiResponseText = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.userId != null) {
      userId = widget.userId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id') ?? 'guest';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _isOn = false;
    _controller.dispose();
    _audioRecorder.dispose();
    TtsService.stop();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (isProcessing && !_isOn) return;

    await TtsService.stop();

    if (await Permission.microphone.request().isGranted) {
      setState(() {
        _isOn = !_isOn;
      });

      if (_isOn) {
        setState(() {
          liveTranscript = "Listening...";
          aiResponseText = "";
          _controller.repeat(reverse: true);
        });
        _startLoop();
      } else {
        setState(() {
          liveTranscript = "Paused.";
          _controller.stop();
          _controller.reset();
        });
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required.")),
        );
      }
    }
  }

  // 🟢 FIX: Continuous chunking loop for live UI updates
  Future<void> _startLoop() async {
    while (_isOn && mounted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        // Record for 3 seconds per chunk
        await Future.delayed(const Duration(seconds: 3));

        if (!_isOn) {
          await _audioRecorder.stop();
          break;
        }

        final savedPath = await _audioRecorder.stop();
        if (savedPath != null && _isOn) {
          _processChunk(savedPath); // Fire and forget so we can instantly start next chunk
        }
      } catch (e) {
        debugPrint("Loop Error: $e");
      }
    }
  }

  Future<void> _processChunk(String path) async {
    if (!mounted || !_isOn || userId == null) return;

    try {
      final result = await _apiService.uploadAudio(userId!, path);

      final transcript = result['transcript']?.toString().trim() ?? "";
      final aiReply = result['ai_response']?.toString().trim() ?? "";
      final action = result['action']?.toString() ?? "";

      if (!mounted || !_isOn) return;

      // Update transcript live as the backend joins the sentences together
      if (transcript.isNotEmpty) {
        setState(() {
          liveTranscript = transcript;
        });
      }

      // If backend NLP triggers an AI response
      if (aiReply.isNotEmpty && action != 'buffering') {
        setState(() {
          aiResponseText = aiReply;
          isProcessing = false;
        });
        await TtsService.speak(aiReply);
      } else if (action == 'crud_required' || action == 'stored') {
        setState(() {
          isProcessing = true;
          aiResponseText = "Thinking...";
        });
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted && _isOn) {
        setState(() {
          liveTranscript = "Connection Error...";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final pulse = _isOn
                          ? 180.0 + (_controller.value * 20.0)
                          : 180.0;

                      return Container(
                        width: pulse,
                        height: pulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.mintGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kPrimaryTeal.withOpacity(
                                  _isOn ? 0.6 : 0.2),
                              blurRadius: _isOn ? 50 : 20,
                              spreadRadius: _isOn ? 10 : 0,
                            )
                          ],
                        ),
                        child: Icon(
                          isProcessing
                              ? Icons.hourglass_empty
                              : (_isOn ? Icons.stop : Icons.mic),
                          size: 70,
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildResponsePanel(),
        ],
      ),
    );
  }

  Widget _buildResponsePanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.kCardDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              liveTranscript.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.kPrimaryTeal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              aiResponseText.isEmpty
                  ? "MindMate is ready."
                  : aiResponseText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (isProcessing)
              const LinearProgressIndicator(
                backgroundColor: Colors.black,
                color: AppTheme.kPrimaryTeal,
              ),
          ],
        ),
      ),
    );
  }
}