import 'dart:ui';
import 'package:flutter/material.dart';
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;           // Add this
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding; // Add this

  const GlassContainer({
    super.key, 
    required this.child, 
    this.blur = 15.0, 
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}