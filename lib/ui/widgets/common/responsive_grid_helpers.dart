import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_layout.dart';

/// Utility class for responsive grid layout calculations
class ResponsiveGridHelpers {
  /// Get maximum card width based on screen size
  static double getMaxCardWidth(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return 200.0;
      case DeviceSizeClass.medium:
        return 230.0;
      case DeviceSizeClass.large:
        return 260.0;
      case DeviceSizeClass.extraLarge:
        return 280.0;
    }
  }

  /// Get child aspect ratio based on screen size (width / height)
  static double getChildAspectRatio(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return 1.05; // slightly wider than tall
      case DeviceSizeClass.medium:
        return 1.10;
      case DeviceSizeClass.large:
        return 1.15;
      case DeviceSizeClass.extraLarge:
        return 1.20;
    }
  }

  /// Create a responsive grid delegate
  static SliverGridDelegate createResponsiveGridDelegate(BuildContext context) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: getMaxCardWidth(context),
      childAspectRatio: getChildAspectRatio(context),
      crossAxisSpacing: context.responsiveGutter,
      mainAxisSpacing: context.responsiveGutter,
    );
  }

  /// Calculate the number of columns that can fit in the available width.
  static int getColumnCount(
    BuildContext context, {
    double minTileWidth = 200,
    int maxColumns = 6,
  }) {
    final horizontalPadding = context.pageHorizontalPadding * 2;
    final availableWidth =
        ResponsiveSpacing.maxContentWidth(context) - horizontalPadding;
    final tileWidth = math.max(minTileWidth, getMaxCardWidth(context));
    final gutter = context.responsiveGutter;
    final columns = ((availableWidth + gutter) / (tileWidth + gutter)).floor();
    return columns.clamp(1, maxColumns);
  }

  /// Determine horizontal padding for grids aligning with page padding.
  static EdgeInsets gridPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: context.pageHorizontalPadding);
  }
}
