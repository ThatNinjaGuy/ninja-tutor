import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Animated XP progress bar with level display
class XPProgressBar extends StatefulWidget {
  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.currentLevel,
    this.height = 12,
    this.showLabel = true,
  });

  final int currentXP;
  final int xpForNextLevel;
  final int currentLevel;
  final double height;
  final bool showLabel;

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;
  double _displayedProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final progress = (widget.currentXP / widget.xpForNextLevel).clamp(0.0, 1.0);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _controller.addListener(() {
      setState(() {
        _displayedProgress = _progressAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(XPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP) {
      final progress = (widget.currentXP / widget.xpForNextLevel).clamp(0.0, 1.0);
      
      _progressAnimation = Tween<double>(
        begin: _displayedProgress,
        end: progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${widget.currentLevel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.xpColor,
                ),
              ),
              Text(
                '${widget.currentXP}/${widget.xpForNextLevel} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (widget.showLabel) const SizedBox(height: 8),
        
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Background track
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                
                // Progress with gradient
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: AppTheme.xpGradient,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.xpColor.withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Shimmer effect
                if (_displayedProgress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      child: _buildShimmer(),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: _displayedProgress,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value,
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Level badge with medal design and glow
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
    this.glowIntensity = 0.5,
  });

  final int level;
  final double size;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: size * 1.3,
          height: size * 1.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppTheme.createGlow(AppTheme.xpColor, intensity: glowIntensity),
          ),
        ),
        
        // Outer medal ring
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.goldColor,
                AppTheme.goldColor.withOpacity(0.7),
                AppTheme.goldColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(size * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.xpGradient,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Star decoration in background
                Icon(
                  Icons.star,
                  size: size * 0.5,
                  color: Colors.white.withOpacity(0.2),
                ),
                
                // Level number
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LVL',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.bold,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular XP progress ring
class XPProgressRing extends StatefulWidget {
  const XPProgressRing({
    super.key,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.currentLevel,
    this.size = 120,
    this.strokeWidth = 8,
  });

  final int currentXP;
  final int xpForNextLevel;
  final int currentLevel;
  final double size;
  final double strokeWidth;

  @override
  State<XPProgressRing> createState() => _XPProgressRingState();
}

class _XPProgressRingState extends State<XPProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final progress = (widget.currentXP / widget.xpForNextLevel).clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(begin: 0.0, end: progress)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(XPProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP) {
      final progress = (widget.currentXP / widget.xpForNextLevel).clamp(0.0, 1.0);
      _progressAnimation = Tween<double>(begin: _progressAnimation.value, end: progress)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _XPRingPainter(
                  progress: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
              );
            },
          ),
          
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Level',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '${widget.currentLevel}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.xpColor,
                ),
              ),
              Text(
                '${((_progressAnimation.value) * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for XP ring
class _XPRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;

  _XPRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = const SweepGradient(
      colors: [
        Color(0xFFFBBF24),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
      ],
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_XPRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

