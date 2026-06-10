// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static bool _isSpeaking  = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        // ignore: avoid_print
        print('[TTS] Error: $msg');
      });

      _initialized = true;
      // ignore: avoid_print
      print('[TTS] Initialized.');
    } catch (e) {
      // ignore: avoid_print
      print('[TTS] Init error: $e');
    }
  }

  /// Speak text. Stops any ongoing speech first.
  static Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (!_initialized) await init();

    try {
      if (_isSpeaking) await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await _tts.speak(text);
    } catch (e) {
      // ignore: avoid_print
      print('[TTS] Speak error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      // ignore: avoid_print
      print('[TTS] Stop error: $e');
    }
  }

  static bool get isSpeaking => _isSpeaking;
}