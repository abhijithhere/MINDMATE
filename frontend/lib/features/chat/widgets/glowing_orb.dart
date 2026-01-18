import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GlowingOrb extends StatefulWidget {
  final bool isListening;
  const GlowingOrb({super.key, required this.isListening});

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // The Gradient
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2C3E50),
                Color(0xFF00DC82), // Mint
                Color(0xFF00F0FF), // Cyan
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // The Glow
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryMint.withOpacity(0.3),
                blurRadius: 40 + (widget.isListening ? 10 * _controller.value : 0),
                spreadRadius: 10 + (widget.isListening ? 15 * _controller.value : 0),
              )
            ],
          ),
          child: Container(
             // Inner shadow overlay for depth
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               gradient: RadialGradient(
                 colors: [
                   Colors.transparent,
                   Colors.black.withOpacity(0.3),
                 ],
               ),
             ),
          ),
        );
      },
    );
  }
}