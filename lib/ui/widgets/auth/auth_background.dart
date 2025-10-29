import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Animated gradient background used across authentication screens.
class AuthAnimatedBackground extends StatelessWidget {
  const AuthAnimatedBackground({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ).value;

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.12),
                      colorScheme.secondary.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120 + (40 * (1 - progress)),
              left: -60,
              child: _GlowingBlob(
                size: 260,
                colors: [
                  colorScheme.primary.withOpacity(0.35),
                  colorScheme.secondary.withOpacity(0.25),
                ],
              ),
            ),
            Positioned(
              bottom: -140 + (30 * progress),
              right: -80,
              child: _GlowingBlob(
                size: 300,
                colors: [
                  AppTheme.aiTipColor.withOpacity(0.28),
                  colorScheme.primary.withOpacity(0.22),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowingBlob extends StatelessWidget {
  const _GlowingBlob({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
        ),
      ),
    );
  }
}

