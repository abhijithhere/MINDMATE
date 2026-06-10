import 'package:flutter/material.dart';

class WaveformVisualizer extends StatelessWidget {
  final bool isActive;
  final Color color;

  const WaveformVisualizer({
    super.key, 
    required this.isActive, 
    this.color = Colors.tealAccent
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox(height: 100);

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(15, (index) => _buildBar(index)),
      ),
    );
  }

  Widget _buildBar(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100 + (index * 20)),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 4,
      height: isActive ? (20.0 + (index % 5 * 10)) : 4,
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}