import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

/// Animated flame icon for streak display
class StreakFlame extends StatefulWidget {
  const StreakFlame({
    super.key,
    required this.streak,
    this.size = 32,
    this.showNumber = true,
  });

  final int streak;
  final double size;
  final bool showNumber;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flameAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _flameAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getFlameColor() {
    if (widget.streak >= 100) return Colors.purple;
    if (widget.streak >= 30) return const Color(0xFFFBBF24); // Gold
    if (widget.streak >= 7) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (widget.streak > 0)
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getFlameColor().withOpacity(_glowAnimation.value * 0.4),
                      blurRadius: 20 * _glowAnimation.value,
                    ),
                  ],
                ),
              ),
            
            // Flame icon
            Transform.scale(
              scale: _flameAnimation.value,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: widget.streak == 0
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : [
                          _getFlameColor(),
                          _getFlameColor().withOpacity(0.7),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Icon(
                  widget.streak == 0 
                      ? Icons.local_fire_department_outlined
                      : Icons.local_fire_department,
                  size: widget.size,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Streak number
            if (widget.showNumber && widget.streak > 0)
              Positioned(
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.streakGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _getFlameColor().withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.streak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Streak display card with flame animation
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.onTap,
  });

  final int currentStreak;
  final int longestStreak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: currentStreak > 0
                ? LinearGradient(
                    colors: [
                      AppTheme.streakColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StreakFlame(streak: currentStreak, size: 40),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreak == 0 ? 'Start Your Streak!' : '$currentStreak Day Streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentStreak == 0
                          ? 'Read today to start a streak'
                          : 'Best: $longestStreak days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (currentStreak > 0)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

