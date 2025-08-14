// widgets/animated_typing_indicator.dart
import 'package:flutter/material.dart';

class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator({super.key});

  @override
  _AnimatedTypingIndicatorState createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final animation = Tween<double>(begin: 1, end: 1.5).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval((index) * 0.2, (index * 0.2) + 0.5, curve: Curves.easeOut),
              ),
            );
            return ScaleTransition(
              scale: animation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}