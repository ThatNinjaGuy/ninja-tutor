import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Utility class for responsive grid layout calculations
class ResponsiveGridHelpers {
  /// Get maximum card width based on screen size
  static double getMaxCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Set reasonable card width limits based on screen size
    if (screenWidth >= AppConstants.desktopBreakpoint) {
      // Desktop: cards should be between 220-320px wide
      return 320.0;
    } else if (screenWidth >= AppConstants.tabletBreakpoint) {
      // Tablet: cards should be between 200-280px wide
      return 280.0;
    } else {
      // Mobile: cards should be between 180-240px wide
      return 240.0;
    }
  }

  /// Get child aspect ratio based on screen size
  static double getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust aspect ratio based on screen size for better proportions
    if (screenWidth >= AppConstants.desktopBreakpoint) {
      // Desktop: wider cards with more height to prevent overflow
      return 0.9;
    } else if (screenWidth >= AppConstants.tabletBreakpoint) {
      // Tablet: balanced proportions with more height
      return 0.85;
    } else {
      // Mobile: taller cards for better text readability and no overflow
      return 0.8;
    }
  }

  /// Create a responsive grid delegate
  static SliverGridDelegate createResponsiveGridDelegate(BuildContext context) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: getMaxCardWidth(context),
      childAspectRatio: getChildAspectRatio(context),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }
}

