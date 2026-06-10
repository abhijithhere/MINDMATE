// lib/features/chat/screens/home_orb_screen.dart
//
// Fixes:
//  1. Reads real user_id from SharedPreferences (not "admin")
//  2. TTS speaks every AI response
//  3. Three info boxes: LIVE TRANSCRIPT / STORED CONTENT / MINDMATE REPLY
//  4. Shows what was saved + where + summary
//  5. No login gate on toggle

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/tts_service.dart';
import '../widgets/glowing_orb.dart';

class HomeOrbScreen extends StatefulWidget {
  final String? userId;
  const HomeOrbScreen({super.key, this.userId});

  @override
  State<HomeOrbScreen> createState() => _HomeOrbScreenState();
}

class _HomeOrbScreenState extends State<HomeOrbScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final ApiService    _api      = ApiService();

  String _userId = '';
  bool   _isOn   = false;

  final ValueNotifier<bool>   _processing = ValueNotifier(false);
  final ValueNotifier<bool>   _verified   = ValueNotifier(false);
  final ValueNotifier<double> _amplitude  = ValueNotifier(0.0);
  final ValueNotifier<String> _transcript = ValueNotifier('Toggle to start listening...');
  final ValueNotifier<String> _savedInfo  = ValueNotifier('Nothing stored yet.');
  final ValueNotifier<String> _aiReply    = ValueNotifier('');

  Timer? _ampTimer;
  double _lastAmp = -1.0;

  @override
  void initState() {
    super.initState();
    TtsService.init();
    _resolveUserId();
  }

  /// Reads the real logged-in user id from SharedPreferences.
  /// Falls back to widget param, then "guest".
  /// This is why "admin" was being sent — the prefs key wasn't set after login.
  Future<void> _resolveUserId() async {
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      setState(() => _userId = widget.userId!);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    // Try multiple common keys that login screens might use
    final id = prefs.getString('user_id') ??
               prefs.getString('userId') ??
               prefs.getString('email') ??
               '';
    setState(() {
      _userId = id.isNotEmpty ? id : 'guest';
    });
    debugPrint('[HomeOrbScreen] Resolved userId: $_userId');
  }

  @override
  void dispose() {
    _stopAll();
    _recorder.dispose();
    _processing.dispose();
    _verified.dispose();
    _amplitude.dispose();
    _transcript.dispose();
    _savedInfo.dispose();
    _aiReply.dispose();
    super.dispose();
  }

  Future<void> _stopAll() async {
    _isOn = false;
    _ampTimer?.cancel();
    _ampTimer = null;
    if (await _recorder.isRecording()) await _recorder.stop();
    _amplitude.value  = 0.0;
    _processing.value = false;
    _lastAmp = -1.0;
  }

  // ── Toggle — zero login check ─────────────────────────────────────────────
  void _toggle(bool val) async {
    if (_isOn == val) return;
    setState(() => _isOn = val);

    if (_isOn) {
      await TtsService.stop();
      _transcript.value = 'Listening...';
      _aiReply.value    = '';
      _savedInfo.value  = 'Nothing stored yet.';
      _verified.value   = false;
      _startLoop();
      _startAmplitude();
    } else {
      await _stopAll();
      await TtsService.stop();
      _transcript.value = 'Toggle to start listening...';
    }
  }

  // ── 3-second recording loop ───────────────────────────────────────────────
  Future<void> _startLoop() async {
    while (_isOn && mounted) {
      try {
        if (!await _recorder.hasPermission()) {
          _transcript.value = 'Microphone permission denied.';
          break;
        }
        if (!_isOn) break;

        final dir  = await getTemporaryDirectory();
        final path = '${dir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1,
          ),
          path: path,
        );

        // 🟢 FIX: Changed from 3 seconds to 5 seconds
        await Future.delayed(const Duration(seconds: 6)); 
        
        if (!_isOn) { await _recorder.stop(); break; }

        final saved = await _recorder.stop();
        if (saved != null && _isOn) _processChunk(saved);
      } catch (e) {
        debugPrint('Loop error: $e');
      }
    }
  }

  // ── Upload + update all 3 boxes + TTS speak ───────────────────────────────
  Future<void> _processChunk(String path) async {
    if (!mounted || !_isOn) return;
    _processing.value = true;

    try {
      final result = await _api.uploadAudio(_userId, path);

      final String transcript   = result['transcript']?.toString().trim() ?? '';
      final bool   authVerified = result['auth_verified'] == true;
      final int    flag         = (result['flag'] is int)
          ? result['flag'] as int
          : int.tryParse(result['flag']?.toString() ?? '0') ?? 0;
      final String action  = result['action']?.toString() ?? '';
      final String table   = result['table']?.toString() ?? '';
      final String summary = result['summary']?.toString() ?? '';
      final String reply   = (result['ai_response'] ?? '').toString().trim();

      if (!mounted || !_isOn) return;

      // ── Box 1: LIVE TRANSCRIPT ─────────────────────────────────────────────
      if (transcript.isNotEmpty) {
        _transcript.value = transcript;
      }

      // ── Voice verified badge ───────────────────────────────────────────────
      _verified.value = authVerified;

      // ── Box 2: STORED CONTENT ─────────────────────────────────────────────
      switch (action) {
        case 'stored':
          final t = table.isNotEmpty ? table : 'database';
          final s = summary.isNotEmpty ? '\n"$summary"' : '';
          _savedInfo.value = '✅ Saved to: $t$s';

        case 'ignored':
          _savedInfo.value = '💭 Casual — nothing stored.';

        case 'buffering':
          _savedInfo.value = '⏳ Still listening...';

        case 'unverified':
          _savedInfo.value = '🔒 Voice not verified (flag=0).\n'
              'Transcript shown but not stored.\n'
              'Speak clearly — ensure admin.wav matches your voice.';

        case 'retrieval_blocked':
          _savedInfo.value = '🔒 Data retrieval blocked — voice unverified.';

        case 'crud_required':
          _savedInfo.value = '🔍 Searching your data...';

        case 'email_sent':
          _savedInfo.value = '📧 Email sent successfully.';

        case 'error':
          final err = result['error']?.toString() ?? 'Unknown error';
          _savedInfo.value = '⚠️ Error: $err';

        case 'silence':
          // Keep previous value — nothing to update
          break;

        default:
          if (flag == 0 && transcript.isNotEmpty) {
            _savedInfo.value = '🔒 Unverified — not stored.';
          }
      }

      // ── Box 3: MINDMATE SAYS (AI reply) + TTS ─────────────────────────────
      if (reply.isNotEmpty) {
        _aiReply.value = reply;
        // Speak the reply via TTS
        if (_isOn && mounted) {
          await TtsService.speak(reply);
        }
      }

    } catch (e) {
      debugPrint('processChunk error: $e');
      if (mounted) {
        _savedInfo.value = '⚠️ Connection error — is the server running?';
      }
    } finally {
      _processing.value = false;
    }
  }

  // ── Amplitude polling ─────────────────────────────────────────────────────
  void _startAmplitude() {
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!mounted || !_isOn || _processing.value) return;
      try {
        final amp        = await _recorder.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        if ((normalized - _lastAmp).abs() > 0.03) {
          _lastAmp         = normalized;
          _amplitude.value = normalized;
        }
      } catch (_) {}
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBadgeRow(),
            Expanded(child: _buildOrbArea()),
            // Box 1: Live transcript
            ValueListenableBuilder<String>(
              valueListenable: _transcript,
              builder: (_, t, __) => _InfoBox(
                title: 'LIVE TRANSCRIPT',
                content: t,
                textColor: Colors.white70,
                icon: Icons.mic_none,
              ),
            ),
            // Box 2: Stored content
            ValueListenableBuilder<String>(
              valueListenable: _savedInfo,
              builder: (_, t, __) => _InfoBox(
                title: 'STORED CONTENT',
                content: t,
                textColor: AppTheme.kPrimaryTeal,
                icon: Icons.save_alt_rounded,
              ),
            ),
            // Box 3: AI reply (hidden when empty)
            ValueListenableBuilder<String>(
              valueListenable: _aiReply,
              builder: (_, t, __) => t.isEmpty
                  ? const SizedBox.shrink()
                  : _InfoBox(
                      title: 'MINDMATE',
                      content: t,
                      textColor: Colors.amberAccent,
                      icon: Icons.auto_awesome,
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MINDMATE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      fontSize: 15)),
              Text(
                _userId.isNotEmpty ? _userId : 'guest',
                style: const TextStyle(fontSize: 8, color: Colors.white30),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                _isOn ? 'LISTENING' : 'SLEEPING',
                style: TextStyle(
                    color: _isOn ? AppTheme.kPrimaryTeal : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isOn,
                onChanged: _toggle,
                activeColor: AppTheme.kPrimaryTeal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    if (!_isOn) return const SizedBox(height: 4);
    return ValueListenableBuilder<bool>(
      valueListenable: _verified,
      builder: (_, v, __) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              v ? Icons.verified_user : Icons.gpp_maybe_outlined,
              color: v ? Colors.greenAccent : Colors.orange,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              v ? 'VOICE VERIFIED (flag=1)' : 'UNVERIFIED (flag=0)',
              style: TextStyle(
                  color: v ? Colors.greenAccent : Colors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbArea() {
    return Center(
      child: SizedBox(
        width: 220, height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isOn)
              RepaintBoundary(
                child: _WaveCanvas(
                    amplitude: _amplitude, processing: _processing),
              ),
            RepaintBoundary(
              child: ValueListenableBuilder<bool>(
                valueListenable: _processing,
                builder: (_, proc, __) =>
                    GlowingOrb(isListening: _isOn, isProcessing: proc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave Canvas
// ─────────────────────────────────────────────────────────────────────────────
class _WaveCanvas extends StatefulWidget {
  final ValueNotifier<double> amplitude;
  final ValueNotifier<bool>   processing;
  const _WaveCanvas({required this.amplitude, required this.processing});
  @override State<_WaveCanvas> createState() => _WaveCanvasState();
}

class _WaveCanvasState extends State<_WaveCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _amp = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    widget.amplitude.addListener(_onAmp);
  }

  void _onAmp() => _amp = widget.amplitude.value;

  @override
  void dispose() {
    _ctrl.dispose();
    widget.amplitude.removeListener(_onAmp);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _WavePainter(
            phase:      _ctrl.value * 2 * math.pi,
            amplitude:  _amp,
            processing: widget.processing.value,
          ),
          size: const Size(220, 220),
        ),
      );
}

class _WavePainter extends CustomPainter {
  final double phase, amplitude;
  final bool processing;
  _WavePainter({required this.phase, required this.amplitude, required this.processing});

  @override
  void paint(Canvas canvas, Size size) {
    final c     = Offset(size.width / 2, size.height / 2);
    final r     = size.width / 2;
    final paint = Paint()
      ..color = (processing ? AppTheme.kPrimaryTeal : Colors.white24)
            .withOpacity(0.45)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final ri = r * (0.5 + amplitude * 0.35 + i * 0.07) +
          math.sin(phase + i * 1.1) * 5 * amplitude;
      canvas.drawCircle(c, ri.clamp(0.0, r), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) =>
      o.phase != phase || o.amplitude != amplitude || o.processing != processing;
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Box
// ─────────────────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final String title, content;
  final Color  textColor;
  final IconData icon;

  const _InfoBox({
    required this.title,
    required this.content,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        width:   double.infinity,
        margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        AppTheme.kCardDark,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: textColor, size: 10),
              const SizedBox(width: 4),
              Text(title,
                  style: TextStyle(
                      color: textColor, fontSize: 9,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 5),
            Text(content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4)),
          ],
        ),
      );
}