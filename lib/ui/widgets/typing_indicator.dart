import 'package:flutter/material.dart';

/// Animated typing indicator like ChatGPT/Gemini
class TypingIndicator extends StatefulWidget {
  final String message;

  const TypingIndicator({
    super.key,
    this.message = 'Analyzing...',
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 6),
          _buildDot(1),
          const SizedBox(width: 6),
          _buildDot(2),
          const SizedBox(width: 12),
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value - delay).clamp(0.0, 1.0);
        final opacity =
            (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
