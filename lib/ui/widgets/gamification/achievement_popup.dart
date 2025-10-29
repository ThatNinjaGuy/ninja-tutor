import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../models/gamification/achievement_model.dart';

/// Achievement unlock popup with confetti animation
class AchievementPopup extends StatefulWidget {
  const AchievementPopup({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  final Achievement achievement;
  final VoidCallback? onDismiss;

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;
  late AnimationController _badgeSpinController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _badgeSpinController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Trigger animations
    HapticsHelper.achievement();
    _controller.forward();
    _confettiController.play();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _badgeSpinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getBadgeColor() {
    switch (widget.achievement.tier) {
      case BadgeTier.bronze:
        return AppTheme.bronzeColor;
      case BadgeTier.silver:
        return AppTheme.silverColor;
      case BadgeTier.gold:
        return AppTheme.goldColor;
      case BadgeTier.platinum:
        return AppTheme.platinumColor;
      case BadgeTier.diamond:
        return Colors.lightBlueAccent;
    }
  }

  IconData _getIconData() {
    // Map achievement types to icons
    switch (widget.achievement.type) {
      case AchievementType.readingMilestone:
        return Icons.auto_stories;
      case AchievementType.quizMastery:
        return Icons.quiz;
      case AchievementType.streakRecord:
        return Icons.local_fire_department;
      case AchievementType.perfectScore:
        return Icons.star;
      case AchievementType.noteCollection:
        return Icons.note;
      case AchievementType.timeInvested:
        return Icons.schedule;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _getBadgeColor();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: [
              badgeColor,
              AppTheme.xpColor,
              theme.colorScheme.primary,
              AppTheme.readingColor,
            ],
          ),
        ),

        // Achievement card
        GestureDetector(
          onTap: _dismiss,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.surface.withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: badgeColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge icon
                        Container(
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _badgeSpinController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _badgeSpinController.value * math.pi * 2,
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    badgeColor,
                                    badgeColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    _getIconData(),
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 10,
                                    child: _Sparkle(color: Colors.white.withOpacity(0.9)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Achievement unlocked text
                        Text(
                          'Achievement Unlocked!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Achievement title
                        Text(
                          widget.achievement.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Achievement description
                        Text(
                          widget.achievement.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // XP reward
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.xpGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.xpColor.withOpacity(0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${widget.achievement.xpReward} XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tap to dismiss
                        Text(
                          'Tap to dismiss',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Show achievement popup as overlay
void showAchievementPopup(BuildContext context, Achievement achievement) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: AchievementPopup(
          achievement: achievement,
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

