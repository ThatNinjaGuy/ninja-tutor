import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// High-level device size buckets used to adapt layout and spacing.
enum DeviceSizeClass { small, medium, large, extraLarge }

/// Helper methods for reasoning about breakpoints and device classes.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  /// Derive the [DeviceSizeClass] for a given width.
  static DeviceSizeClass sizeClassForWidth(double width) {
    if (width < AppConstants.mobileBreakpoint) {
      return DeviceSizeClass.small;
    }
    if (width < AppConstants.desktopBreakpoint) {
      return DeviceSizeClass.medium;
    }
    if (width < AppConstants.largeDesktopBreakpoint) {
      return DeviceSizeClass.large;
    }
    return DeviceSizeClass.extraLarge;
  }

  /// Convenience method to get the size class from context.
  static DeviceSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return sizeClassForWidth(width);
  }

  static bool isSmall(BuildContext context) =>
      of(context) == DeviceSizeClass.small;

  static bool isMedium(BuildContext context) =>
      of(context) == DeviceSizeClass.medium;

  static bool isLarge(BuildContext context) =>
      of(context) == DeviceSizeClass.large;

  static bool isExtraLarge(BuildContext context) =>
      of(context) == DeviceSizeClass.extraLarge;

  static bool isTabletWidth(double width) {
    return width >= AppConstants.mobileBreakpoint &&
        width < AppConstants.desktopBreakpoint;
  }

  static bool isDesktopWidth(double width) =>
      width >= AppConstants.desktopBreakpoint;
}

/// Utility for selecting values per device class with graceful fallbacks.
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.small,
    this.medium,
    this.large,
    this.extraLarge,
  });

  final T small;
  final T? medium;
  final T? large;
  final T? extraLarge;

  /// Resolve the value for a [BuildContext].
  T resolve(BuildContext context) =>
      resolveForClass(ResponsiveBreakpoints.of(context));

  /// Resolve the value for a specific [DeviceSizeClass].
  T resolveForClass(DeviceSizeClass sizeClass) {
    switch (sizeClass) {
      case DeviceSizeClass.small:
        return small;
      case DeviceSizeClass.medium:
        return medium ?? small;
      case DeviceSizeClass.large:
        return large ?? medium ?? small;
      case DeviceSizeClass.extraLarge:
        return extraLarge ?? large ?? medium ?? small;
    }
  }
}

/// Centralized spacing utilities that adapt to device class.
class ResponsiveSpacing {
  const ResponsiveSpacing._();

  /// General horizontal padding for page-level layouts.
  static double pageHorizontal(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return AppConstants.defaultPadding;
      case DeviceSizeClass.medium:
        return AppConstants.largePadding;
      case DeviceSizeClass.large:
        return AppConstants.extraLargePadding;
      case DeviceSizeClass.extraLarge:
        return AppConstants.extraLargePadding + AppConstants.spacingSM;
    }
  }

  /// General vertical padding for page-level layouts.
  static double pageVertical(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return AppConstants.largePadding;
      case DeviceSizeClass.medium:
        return AppConstants.extraLargePadding;
      case DeviceSizeClass.large:
        return AppConstants.spacingXL;
      case DeviceSizeClass.extraLarge:
        return AppConstants.spacingXXL;
    }
  }

  /// Standard gap between grid/list items.
  static double gutter(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return AppConstants.spacingSM;
      case DeviceSizeClass.medium:
        return AppConstants.spacingMD;
      case DeviceSizeClass.large:
        return AppConstants.spacingLG;
      case DeviceSizeClass.extraLarge:
        return AppConstants.spacingXL;
    }
  }

  /// Maximum content width to keep layouts readable on very wide displays.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= AppConstants.largeDesktopBreakpoint
        ? AppConstants.widePageMaxWidth
        : AppConstants.pageMaxWidth;
    return math.min(width, maxWidth);
  }

  /// Full page padding combined into an [EdgeInsets].
  static EdgeInsets pageInsets(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final horizontal = pageHorizontal(context);
    final vertical = pageVertical(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    ).copyWith(
      top: top ?? vertical,
      bottom: bottom ?? vertical,
    );
  }
}

/// Typography helpers to gently scale text across breakpoints.
class ResponsiveTypography {
  const ResponsiveTypography._();

  /// Suggested scale factor for font sizes at the current breakpoint.
  static double scale(BuildContext context) {
    switch (ResponsiveBreakpoints.of(context)) {
      case DeviceSizeClass.small:
        return 0.96;
      case DeviceSizeClass.medium:
        return 1.0;
      case DeviceSizeClass.large:
        return 1.06;
      case DeviceSizeClass.extraLarge:
        return 1.1;
    }
  }

  /// Apply the responsive scale to an existing [TextStyle].
  static TextStyle adjust(BuildContext context, TextStyle style) {
    final factor = scale(context);
    return style.copyWith(
      fontSize: style.fontSize != null ? style.fontSize! * factor : null,
      letterSpacing: style.letterSpacing != null
          ? style.letterSpacing! * math.sqrt(factor)
          : null,
    );
  }
}

/// Layout helper to provide dedicated builders per device class.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    this.small,
    this.medium,
    this.large,
    this.extraLarge,
    this.builder,
    this.fallback,
  });

  final WidgetBuilder? small;
  final WidgetBuilder? medium;
  final WidgetBuilder? large;
  final WidgetBuilder? extraLarge;
  final Widget Function(BuildContext context, DeviceSizeClass sizeClass)?
      builder;
  final WidgetBuilder? fallback;

  @override
  Widget build(BuildContext context) {
    final sizeClass = ResponsiveBreakpoints.of(context);

    if (builder != null) {
      return builder!(context, sizeClass);
    }

    WidgetBuilder? selected;
    switch (sizeClass) {
      case DeviceSizeClass.small:
        selected = small ?? fallback ?? medium ?? large ?? extraLarge;
        break;
      case DeviceSizeClass.medium:
        selected = medium ?? fallback ?? large ?? small ?? extraLarge;
        break;
      case DeviceSizeClass.large:
        selected = large ?? fallback ?? medium ?? extraLarge ?? small;
        break;
      case DeviceSizeClass.extraLarge:
        selected = extraLarge ?? fallback ?? large ?? medium ?? small;
        break;
    }

    return selected?.call(context) ?? const SizedBox.shrink();
  }
}

extension ResponsiveContext on BuildContext {
  DeviceSizeClass get deviceSizeClass => ResponsiveBreakpoints.of(this);

  double get pageHorizontalPadding => ResponsiveSpacing.pageHorizontal(this);

  double get pageVerticalPadding => ResponsiveSpacing.pageVertical(this);

  EdgeInsets get pagePadding => ResponsiveSpacing.pageInsets(this);

  double get responsiveGutter => ResponsiveSpacing.gutter(this);

  double get responsiveMaxContentWidth =>
      ResponsiveSpacing.maxContentWidth(this);

  double get responsiveTextScale => ResponsiveTypography.scale(this);

  T responsiveValue<T>({
    required T small,
    T? medium,
    T? large,
    T? extraLarge,
  }) {
    return ResponsiveValue<T>(
      small: small,
      medium: medium,
      large: large,
      extraLarge: extraLarge,
    ).resolve(this);
  }
}
