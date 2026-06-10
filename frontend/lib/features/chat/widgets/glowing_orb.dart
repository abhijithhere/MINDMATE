import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GlowingOrb extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double size;

  const GlowingOrb({
    super.key,
    required this.isListening,
    this.isProcessing = false,
    this.size = 280,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ✅ FIX 1: Pre-declare Tween objects outside build().
  // Creating new Tween/Animation objects inside AnimatedBuilder.builder()
  // on every frame allocates garbage that stalls the render pipeline.
  late final Animation<double> _blurAnim;
  late final Animation<double> _spreadAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // ✅ FIX 2: Define animations once in initState, not on every build frame.
    _blurAnim = Tween<double>(begin: 20, end: 60).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _spreadAnim = Tween<double>(begin: 5, end: 25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _handleAnimation();
  }

  @override
  void didUpdateWidget(covariant GlowingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.isProcessing != widget.isProcessing) {
      _handleAnimation();
    }
  }

  void _handleAnimation() {
    if (widget.isListening || widget.isProcessing) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      // ✅ FIX 3: Reset to base state when stopped so shadow doesn't freeze
      // mid-pulse, which looks broken.
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 4: Determine gradient/color values OUTSIDE AnimatedBuilder.
    // These only change when widget props change, not every animation frame.
    final List<Color> gradientColors = widget.isProcessing
        ? [const Color(0xFFFF8C00), Colors.orangeAccent, const Color(0xFFFFD700)]
        : [
            const Color(0xFF2C3E50),
            AppTheme.primaryMint,
            const Color(0xFF00F0FF),
          ];

    final Color glowColor = widget.isProcessing
        ? Colors.orange
        : (widget.isListening ? AppTheme.primaryMint : Colors.grey.shade800);

    final bool isActive = widget.isListening || widget.isProcessing;

    // ✅ FIX 5: AnimatedBuilder only reads _blurAnim and _spreadAnim.
    // The gradient (most expensive part) is built outside and passed as `child`.
    // Flutter reuses the child widget between frames — it's NOT rebuilt on each tick.
    return AnimatedBuilder(
      animation: _controller,
      child: _buildOrbBody(gradientColors, isActive),
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ✅ The child (gradient orb) is passed through, not rebuilt here.
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(isActive ? 0.5 : 0.2),
                blurRadius: isActive ? _blurAnim.value : 20,
                spreadRadius: isActive ? _spreadAnim.value : 5,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  /// ✅ The gradient orb is a separate method that returns a plain widget —
  /// no animations inside. It only rebuilds when widget props change.
  Widget _buildOrbBody(List<Color> gradientColors, bool isActive) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(isActive ? 0.2 : 0.5),
            ],
          ),
        ),
      ),
    );
  }
}