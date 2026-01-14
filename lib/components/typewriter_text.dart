import 'package:flutter/material.dart';
import 'dart:async';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 400),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  List<String> _lines = [];
  List<AnimationController> _controllers = [];
  List<Animation<double>> _fadeAnimations = [];
  List<Animation<Offset>> _slideAnimations = [];
  int _currentChunk = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupText();
    _startAnimation();
  }

  void _setupText() {
    // Split text into lines
    _lines = widget.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // If no line breaks, create chunks of ~80 characters
    if (_lines.length == 1 && _lines[0].length > 80) {
      final words = _lines[0].split(' ');
      _lines.clear();
      String currentLine = '';
      
      for (String word in words) {
        if (currentLine.length + word.length + 1 <= 80) {
          currentLine += (currentLine.isEmpty ? '' : ' ') + word;
        } else {
          if (currentLine.isNotEmpty) _lines.add(currentLine);
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) _lines.add(currentLine);
    }

    // Create animations for each line
    for (int i = 0; i < _lines.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      
      final slideAnimation = Tween<Offset>(
        begin: const Offset(-0.3, -0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );

      _controllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _slideAnimations.add(slideAnimation);
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_currentChunk < _lines.length) {
        // Animate 2-3 lines at once
        final chunkSize = (_lines.length <= 3) ? _lines.length : 2;
        final endIndex = (_currentChunk + chunkSize).clamp(0, _lines.length);
        
        for (int i = _currentChunk; i < endIndex; i++) {
          // Stagger each line slightly
          Timer(Duration(milliseconds: (i - _currentChunk) * 100), () {
            if (mounted && i < _controllers.length) {
              _controllers[i].forward();
            }
          });
        }
        
        _currentChunk = endIndex;
      } else {
        timer.cancel();
        Timer(const Duration(milliseconds: 300), () {
          widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _lines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        
        if (index >= _controllers.length) return const SizedBox.shrink();
        
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: widget.style,
                    softWrap: true,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
