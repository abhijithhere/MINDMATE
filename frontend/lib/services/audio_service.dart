
//frontend\lib\services\audio_service.dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String?> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        // Unique timestamped filename for each 3-second chunk
        final filePath = '${directory.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

        const config = RecordConfig(
          encoder: AudioEncoder.wav, // Essential for Whisper/Biometrics
          sampleRate: 16000,         // Matches Backend STT config
          numChannels: 1,            // Mono
        );

        await _recorder.start(config, path: filePath);
        return filePath;
      }
    } catch (e) {
      print("❌ Recording Start Error: $e");
    }
    return null;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  void dispose() => _recorder.dispose();
}