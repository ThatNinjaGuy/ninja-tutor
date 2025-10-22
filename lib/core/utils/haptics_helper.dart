import 'package:flutter/services.dart';

/// Centralized haptic feedback helper for consistent tactile responses
class HapticsHelper {
  /// Light impact for subtle interactions (taps, selections)
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for important actions (confirmations, completions)
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for critical actions (deletions, errors)
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback for picker/list selections
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Success feedback (medium + light for celebration feel)
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Error feedback (heavy + vibrate for attention)
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Achievement unlock feedback (celebration pattern)
  static void achievement() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }
}

