import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated gradient background with subtle particle effects
class GradientBackground extends StatefulWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(
                      red: math.min(
                          1.0, Theme.of(context).colorScheme.surface.r + 0.05),
                      green: math.min(
                          1.0, Theme.of(context).colorScheme.surface.g + 0.05),
                      blue: math.min(
                          1.0, Theme.of(context).colorScheme.surface.b + 0.1),
                    ),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle animated circles
              ...List.generate(3, (index) {
                final offset = (index * 0.33) + _controller.value;
                return Positioned(
                  left:
                      MediaQuery.of(context).size.width * (offset % 1.0) - 100,
                  top: 100 + (index * 150.0),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              }),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
