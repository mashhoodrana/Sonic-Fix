import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Gemini-style loading indicator with logo and rotating messages
class GeminiStyleLoading extends StatefulWidget {
  const GeminiStyleLoading({super.key});

  @override
  State<GeminiStyleLoading> createState() => _GeminiStyleLoadingState();
}

class _GeminiStyleLoadingState extends State<GeminiStyleLoading>
    with SingleTickerProviderStateMixin {
  int _currentMessageIndex = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _messages = [
    'Listening to audio patterns...',
    'Analyzing sound frequencies...',
    'Checking sound category...',
    'Consulting AI model...',
    'Generating diagnosis...',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startMessageRotation();
  }

  void _startMessageRotation() {
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated logo with glow effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 120 * _pulseAnimation.value,
                    height: 120 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Rotating gradient border
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _RotatingBorderPainter(
                    animation: _pulseController,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              // Logo
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/sonicfix.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_fix_high,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Animated message with fade transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _messages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _messages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentMessageIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentMessageIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rotating gradient border
class _RotatingBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RotatingBorderPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.5),
          color,
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(animation.value * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RotatingBorderPainter oldDelegate) => false;
}
