import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ThinkingAnimation extends StatefulWidget {
  const ThinkingAnimation({super.key});

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _dotsController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0F0F0F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.purple.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final delay = index * 0.15;
                        final progress = (_dotsController.value - delay).clamp(0.0, 1.0);
                        final scale = sin(progress * pi * 2) * 0.5 + 1.0;
                        final opacity = sin(progress * pi * 2) * 0.4 + 0.6;
                        
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
