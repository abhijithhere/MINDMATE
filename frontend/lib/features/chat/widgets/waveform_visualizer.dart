import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ✅ FIX 1: Changed to StatefulWidget.
/// The old StatelessWidget was being entirely DESTROYED and RECREATED by the
/// parent's ValueListenableBuilder on every amplitude update.
/// A StatefulWidget persists across rebuilds — only the CustomPainter repaints.
class WaveVisualizer extends StatefulWidget {
  final double amplitude; // 0.0 to 1.0
  final Color color;

  const WaveVisualizer({
    Key? key,
    required this.amplitude,
    this.color = Colors.blueAccent,
  }) : super(key: key);

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer> {
  @override
  Widget build(BuildContext context) {
    // ✅ FIX 2: Removed the inner RepaintBoundary.
    // The parent HomeOrbScreen already wraps this in a RepaintBoundary.
    // Double-wrapping creates TWO GPU compositing layers for one widget —
    // each layer needs its own buffer slot in the BLASTBufferQueue.
    // One layer = one slot. That's all we need.
    return CustomPaint(
      painter: _WavePainter(widget.amplitude, widget.color),
      size: const Size(280, 280),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude;
  final Color color;

  _WavePainter(this.amplitude, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;

    // ✅ FIX 3: Reuse a single Paint object instead of creating 3 new ones
    // (one per ring per frame). Less GC pressure = smoother frames.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 1; i <= 3; i++) {
      final ringRadius = baseRadius + (amplitude * (1.2 * i) * 40);
      // ✅ FIX 4: Clamp ring radius so it never draws outside the canvas bounds,
      // which previously forced the GPU to clip an oversized layer.
      final clampedRadius = ringRadius.clamp(0.0, size.width / 2);

      paint.color = color.withOpacity((0.4 / i).clamp(0.0, 1.0));
      canvas.drawCircle(center, clampedRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      // ✅ FIX 5: Use a threshold here too — skip repaint if amplitude barely changed.
      // Matches the dead-zone in HomeOrbScreen's amplitude polling.
      (oldDelegate.amplitude - amplitude).abs() > 0.01 ||
      oldDelegate.color != color;
}