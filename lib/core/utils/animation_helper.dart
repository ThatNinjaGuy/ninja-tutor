import 'package:flutter/material.dart';

/// Reusable animation utilities for consistent app animations
class AnimationHelper {
  AnimationHelper._();

  /// Create a slide-in animation from direction
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a fade animation
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeIn,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a curved animation with optional interval for staggered transitions
  static CurvedAnimation createCurvedAnimation({
    required AnimationController controller,
    Curve curve = Curves.easeOutCubic,
    double beginInterval = 0.0,
    double endInterval = 1.0,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: Interval(beginInterval, endInterval, curve: curve),
    );
  }

  /// Create a scale animation
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a scale pulse animation for micro-interactions (e.g., button press)
  static Animation<double> createPulseAnimation({
    required AnimationController controller,
    double minScale = 0.96,
    double maxScale = 1.04,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: maxScale)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: maxScale, end: minScale)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: minScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
    ]).animate(controller);
  }

  /// Create a rotation animation
  static Animation<double> createRotationAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a shake animation for error feedback
  static Animation<double> createShakeAnimation({
    required AnimationController controller,
    double magnitude = 12,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -magnitude)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -magnitude, end: magnitude)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: magnitude, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(controller);
  }

  /// Create a color animation
  static Animation<Color?> createColorAnimation({
    required AnimationController controller,
    required Color begin,
    required Color end,
    Curve curve = Curves.easeInOut,
  }) {
    return ColorTween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Standard durations
  static const Duration micro = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration extraSlow = Duration(milliseconds: 1100);

  /// Standard curves
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeOutQuint = Curves.easeOutQuint;
  static const Curve easeInOutCirc = Curves.easeInOutCirc;
  static const Curve easeInQuad = Curves.easeInQuad;

  /// Helper to build staggered intervals for list animations
  static Interval createStaggerInterval(
    int index,
    int itemCount, {
    double start = 0.0,
    double end = 1.0,
    double overlap = 0.15,
    Curve curve = Curves.easeOutCubic,
  }) {
    assert(itemCount > 0, 'itemCount must be greater than zero');
    final segment = (end - start) / itemCount;
    final adjustedSegment = segment * (1 + overlap);
    final intervalStart = (start + index * segment).clamp(0.0, 1.0);
    final intervalEnd = (intervalStart + adjustedSegment).clamp(0.0, 1.0);

    return Interval(intervalStart, intervalEnd, curve: curve);
  }

  /// Create an animation based on a provided tween and staggered interval
  static Animation<T> createStaggeredTween<T>({
    required AnimationController controller,
    required Animatable<T> tween,
    required Interval interval,
  }) {
    return tween.animate(CurvedAnimation(parent: controller, curve: interval));
  }

  /// Create shimmering offset animation for skeleton loaders
  static Animation<double> createShimmerAnimation({
    required AnimationController controller,
    double begin = -1.0,
    double end = 2.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }
}

