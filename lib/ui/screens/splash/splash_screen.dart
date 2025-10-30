import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../core/utils/responsive_layout.dart';

/// Splash screen shown on app startup
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late AnimationController _glowController;
  late Animation<double> _glowPulse;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _taglineFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    _taglineSlide = AnimationHelper.createSlideAnimation(
      controller: _fadeController,
      begin: const Offset(0, 0.2),
      end: Offset.zero,
      curve: Curves.easeOutCubic,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowPulse = AnimationHelper.createPulseAnimation(
      controller: _glowController,
      minScale: 0.95,
      maxScale: 1.05,
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for Firebase auth state to settle
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Always go to dashboard - auth screens will be shown automatically if needed
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final heroSize = context.responsiveValue(
      small: 104.0,
      medium: 128.0,
      large: 148.0,
      extraLarge: 168.0,
    );
    final iconSize = context.responsiveValue(
      small: 56.0,
      medium: 68.0,
      large: 76.0,
      extraLarge: 84.0,
    );
    final spacing = context.responsiveValue(
      small: 28.0,
      medium: 36.0,
      large: 48.0,
      extraLarge: 56.0,
    );
    final textSpacing = spacing * 0.35;
    final maxWidth = context.responsiveValue(
      small: 320.0,
      medium: 420.0,
      large: 520.0,
      extraLarge: 640.0,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.pageHorizontalPadding,
          vertical: spacing,
        ),
        child: Stack(
          children: [
            _SplashBackground(animation: _fadeController),
            AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _scaleAnimation,
              ]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Align(
                      alignment: ResponsiveBreakpoints.isSmall(context)
                          ? Alignment.center
                          : Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _glowPulse,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _glowPulse.value,
                                  child: Container(
                                    width: heroSize,
                                    height: heroSize,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius:
                                          BorderRadius.circular(heroSize / 4),
                                      boxShadow: AppTheme.createGlow(
                                        colorScheme.primary,
                                        intensity: 0.45,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      size: iconSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: spacing),
                            Text(
                              AppConstants.appName,
                              textAlign: TextAlign.center,
                              style: ResponsiveTypography.adjust(
                                context,
                                theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onBackground,
                                    ) ??
                                    TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onBackground,
                                      fontSize: 28,
                                    ),
                              ),
                            ),
                            SizedBox(height: textSpacing),
                            SlideTransition(
                              position: _taglineSlide,
                              child: FadeTransition(
                                opacity: _taglineFade,
                                child: Text(
                                  'AI-enhanced learning journeys',
                                  textAlign: TextAlign.center,
                                  style: ResponsiveTypography.adjust(
                                    context,
                                    theme.textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onBackground
                                              .withOpacity(0.72),
                                          letterSpacing: 0.2,
                                        ) ??
                                        TextStyle(
                                          color: colorScheme.onBackground
                                              .withOpacity(0.72),
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: spacing * 0.9),
                            _ProgressDots(
                              controller: _dotsController,
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topOrbSize = context.responsiveValue(
      small: 220.0,
      medium: 260.0,
      large: 300.0,
      extraLarge: 340.0,
    );
    final bottomOrbSize = context.responsiveValue(
      small: 260.0,
      medium: 300.0,
      large: 340.0,
      extraLarge: 380.0,
    );
    final horizontalOffset = context.responsiveValue(
      small: 70.0,
      medium: 80.0,
      large: 90.0,
      extraLarge: 100.0,
    );
    final topOffsetBase = context.responsiveValue(
      small: -120.0,
      medium: -140.0,
      large: -160.0,
      extraLarge: -180.0,
    );
    final bottomOffsetBase = context.responsiveValue(
      small: -140.0,
      medium: -160.0,
      large: -180.0,
      extraLarge: -200.0,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ).value;

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.secondary.withOpacity(0.08),
                      AppTheme.aiTipColor.withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: topOffsetBase + 40 * (1 - progress),
              left: -horizontalOffset,
              child: _GlowingOrb(
                size: topOrbSize,
                colors: [
                  colorScheme.primary.withOpacity(0.28),
                  colorScheme.secondary.withOpacity(0.18),
                ],
              ),
            ),
            Positioned(
              bottom: bottomOffsetBase + 32 * progress,
              right: -horizontalOffset,
              child: _GlowingOrb(
                size: bottomOrbSize,
                colors: [
                  AppTheme.aiTipColor.withOpacity(0.24),
                  colorScheme.primary.withOpacity(0.16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.controller,
    required this.activeColor,
  });

  final AnimationController controller;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final activeIndex = ((controller.value * 3)).floor() % 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == activeIndex;
            return AnimatedContainer(
              duration: AnimationHelper.fast,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isActive ? 16 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive ? activeColor : activeColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        );
      },
    );
  }
}
