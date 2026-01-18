import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/theme/app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  const WaveformVisualizer({super.key, required this.isActive});

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Random height simulation
              double height = widget.isActive 
                  ? 10 + Random().nextInt(40).toDouble() 
                  : 5.0;
              return Container(
                width: 6,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: widget.isActive ? AppTheme.kPrimaryTeal : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}