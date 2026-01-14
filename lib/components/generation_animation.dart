import 'package:flutter/material.dart';
import 'dart:math';

class GenerationAnimation extends StatefulWidget {
  final String type; // 'image' or 'video'
  final String? url;
  final String prompt;
  final VoidCallback? onTap;

  const GenerationAnimation({
    super.key,
    required this.type,
    this.url,
    required this.prompt,
    this.onTap,
  });

  @override
  State<GenerationAnimation> createState() => _GenerationAnimationState();
}

class _GenerationAnimationState extends State<GenerationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _fadeController;
  late List<Animation<Offset>> _ballAnimations;
  late Animation<double> _fadeAnimation;
  
  bool _isGenerated = false;

  @override
  void initState() {
    super.initState();
    
    _ballController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create 3 ball animations with different paths
    _ballAnimations = [
      // Yellow ball - circular motion
      Tween<Offset>(
        begin: const Offset(0.3, 0.4),
        end: const Offset(0.7, 0.6),
      ).animate(CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeInOut,
      )),
      
      // Pink ball - figure-8 motion
      Tween<Offset>(
        begin: const Offset(0.7, 0.3),
        end: const Offset(0.3, 0.7),
      ).animate(CurvedAnimation(
        parent: _ballController,
        curve: Curves.elasticInOut,
      )),
      
      // Blue ball - wave motion
      Tween<Offset>(
        begin: const Offset(0.5, 0.6),
        end: const Offset(0.5, 0.3),
      ).animate(CurvedAnimation(
        parent: _ballController,
        curve: Curves.bounceInOut,
      )),
    ];
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _ballController.repeat(reverse: true);
    
    // Check if content is already generated
    if (widget.url != null && widget.url!.isNotEmpty) {
      _showContent();
    }
  }

  @override
  void didUpdateWidget(GenerationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != null && widget.url!.isNotEmpty && !_isGenerated) {
      _showContent();
    }
  }

  void _showContent() {
    setState(() {
      _isGenerated = true;
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _ballController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 200,
        height: 200 * (3/4), // 4:3 ratio
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Content layer (image/video)
              if (_isGenerated && widget.url != null)
                _buildContent(),
              
              // Animation layer
              AnimatedBuilder(
                animation: Listenable.merge([_ballController, _fadeController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack(
                        children: [
                          // Blur overlay
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                          
                          // Moving balls
                          ..._buildAnimatedBalls(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Prompt text overlay
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.prompt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.type == 'image') {
      return Image.network(
        widget.url!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
      );
    } else {
      // Video thumbnail - you can implement video thumbnail extraction here
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: const Icon(
          Icons.play_circle_fill,
          size: 40,
          color: Colors.white,
        ),
      );
    }
  }

  List<Widget> _buildAnimatedBalls() {
    final colors = [
      Colors.yellow.withOpacity(0.7),
      Colors.pink.withOpacity(0.7),
      Colors.blue.withOpacity(0.7),
    ];
    
    return List.generate(3, (index) {
      return AnimatedBuilder(
        animation: _ballAnimations[index],
        builder: (context, child) {
          // Add some randomness to the motion
          final offset = _ballAnimations[index].value;
          final randomX = sin(_ballController.value * 2 * pi + index) * 0.1;
          final randomY = cos(_ballController.value * 2 * pi + index) * 0.1;
          
          return Positioned(
            left: (offset.dx + randomX) * 200 - 15,
            top: (offset.dy + randomY) * 150 - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
