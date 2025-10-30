import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../core/utils/responsive_layout.dart';

/// Unified loading state widget with support for contextual messaging
/// and optional progress indicators.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    required this.title,
    this.subtitle,
    this.progress,
    this.progressLabel,
    this.indicator,
    this.icon,
    this.tip,
    this.messages,
    this.useCard = true,
    this.showSpinner = true,
    this.padding,
    this.actions,
    this.onCancel,
  });

  /// Primary headline message displayed to the user.
  final String title;

  /// Optional supporting text shown below the title.
  final String? subtitle;

  /// Optional progress value (0.0 - 1.0). When provided the indicator becomes determinate.
  final double? progress;

  /// Optional label displayed next to the progress indicator.
  final String? progressLabel;

  /// Custom indicator widget. When null a spinner / determinate indicator will be used.
  final Widget? indicator;

  /// Optional icon to display when a spinner is not required.
  final IconData? icon;

  /// Optional tip or helper text displayed inside a subtle capsule.
  final String? tip;

  /// Optional additional messages displayed as bullet points.
  final List<String>? messages;

  /// Whether to wrap the loading state inside a decorated card surface.
  final bool useCard;

  /// Whether to show a spinner by default when no custom indicator is provided.
  final bool showSpinner;

  /// Custom padding for the loading state content.
  final EdgeInsetsGeometry? padding;

  /// Optional trailing actions (e.g., cancel button, retry control).
  final Widget? actions;

  /// Optional cancel callback that renders a secondary text button.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalGap = context.responsiveValue(
      small: AppConstants.spacingLG,
      medium: AppConstants.spacingLG + 4,
      large: AppConstants.spacingXL,
      extraLarge: AppConstants.spacingXL + 4,
    );
    final verticalGap = context.responsiveValue(
      small: AppConstants.spacingMD,
      medium: AppConstants.spacingLG,
      large: AppConstants.spacingLG,
      extraLarge: AppConstants.spacingXL,
    );
    final microGap = verticalGap * 0.35;
    final maxWidth = context.responsiveValue(
      small: 520.0,
      medium: 600.0,
      large: 720.0,
      extraLarge: 840.0,
    );

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Indicator(
          indicator: indicator,
          showSpinner: showSpinner,
          progress: progress,
          icon: icon,
        ),
        SizedBox(width: horizontalGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ResponsiveTypography.adjust(
                  context,
                  theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      theme.textTheme.titleLarge ??
                      const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: microGap),
                Text(
                  subtitle!,
                  style: ResponsiveTypography.adjust(
                    context,
                    theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                          height: 1.4,
                        ) ??
                        TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
              if (progressLabel != null || progress != null) ...[
                SizedBox(height: verticalGap * 0.8),
                _ProgressLabel(
                  progress: progress,
                  label: progressLabel,
                ),
              ],
              if (messages != null && messages!.isNotEmpty) ...[
                SizedBox(height: verticalGap * 0.8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages!
                      .map(
                        (message) => Padding(
                          padding: EdgeInsets.only(bottom: microGap),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: EdgeInsets.only(
                                    top: microGap, right: microGap + 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  message,
                                  style: ResponsiveTypography.adjust(
                                    context,
                                    theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          height: 1.35,
                                        ) ??
                                        TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (tip != null) ...[
                SizedBox(height: verticalGap),
                _TipChip(text: tip!),
              ],
              if (actions != null || onCancel != null) ...[
                SizedBox(height: verticalGap),
                Row(
                  children: [
                    if (actions != null) actions!,
                    if (actions != null && onCancel != null)
                      SizedBox(width: horizontalGap * 0.5),
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final effectivePadding = padding ??
        EdgeInsets.all(
          context.responsiveValue(
            small: AppConstants.spacingXL,
            medium: AppConstants.spacingXL,
            large: AppConstants.spacingXL + 4,
            extraLarge: AppConstants.spacingXXL,
          ),
        );

    if (useCard) {
      content = Container(
        decoration: AppTheme.layeredCardDecoration(context, borderRadius: 20),
        padding: effectivePadding,
        child: content,
      );
    } else {
      content = Padding(
        padding: effectivePadding,
        child: content,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

class _Indicator extends StatefulWidget {
  const _Indicator({
    required this.indicator,
    required this.showSpinner,
    required this.progress,
    required this.icon,
  });

  final Widget? indicator;
  final bool showSpinner;
  final double? progress;
  final IconData? icon;

  @override
  State<_Indicator> createState() => _IndicatorState();
}

class _IndicatorState extends State<_Indicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = AnimationHelper.createPulseAnimation(
      controller: _controller,
      minScale: 0.94,
      maxScale: 1.04,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final determinateSize = context.responsiveValue(
      small: 36.0,
      medium: 40.0,
      large: 46.0,
      extraLarge: 52.0,
    );
    final spinnerSize = context.responsiveValue(
      small: 32.0,
      medium: 36.0,
      large: 40.0,
      extraLarge: 44.0,
    );
    final iconSize = context.responsiveValue(
      small: 28.0,
      medium: 32.0,
      large: 36.0,
      extraLarge: 40.0,
    );
    final padding = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingMD,
      large: AppConstants.spacingMD,
      extraLarge: AppConstants.spacingLG,
    );

    Widget indicator;
    if (widget.indicator != null) {
      indicator = widget.indicator!;
    } else if (widget.progress != null) {
      indicator = SizedBox(
        height: determinateSize,
        width: determinateSize,
        child: CircularProgressIndicator(
          value: widget.progress!.clamp(0.0, 1.0),
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        ),
      );
    } else if (widget.showSpinner) {
      indicator = SizedBox(
        height: spinnerSize,
        width: spinnerSize,
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
      );
    } else {
      indicator = Icon(
        widget.icon ?? Icons.auto_awesome,
        size: iconSize,
        color: theme.colorScheme.primary,
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.progress != null ? 1.0 : _pulse.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppTheme.createGlow(
                theme.colorScheme.primary,
                intensity: widget.progress != null ? 0.35 : 0.22,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: child,
            ),
          ),
        );
      },
      child: indicator,
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({
    required this.progress,
    required this.label,
  });

  final double? progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingSM + 2,
      large: AppConstants.spacingMD,
      extraLarge: AppConstants.spacingMD,
    );
    final barHeight = context.responsiveValue(
      small: 6.0,
      medium: 6.0,
      large: 8.0,
      extraLarge: 10.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: ResponsiveTypography.adjust(
              context,
              theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ) ??
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
            ),
          ),
        SizedBox(height: gap),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress?.clamp(0.0, 1.0),
            minHeight: barHeight,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          ),
        ),
        if (progress != null) ...[
          SizedBox(height: gap * 0.8),
          Text(
            '${(progress!.clamp(0.0, 1.0) * 100).round()}% complete',
            style: ResponsiveTypography.adjust(
              context,
              theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontal = context.responsiveValue(
      small: AppConstants.spacingMD,
      medium: AppConstants.spacingLG,
      large: AppConstants.spacingLG,
      extraLarge: AppConstants.spacingXL,
    );
    final vertical = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingSM + 2,
      large: AppConstants.spacingMD,
      extraLarge: AppConstants.spacingMD,
    );
    final iconSize = context.responsiveValue(
      small: 18.0,
      medium: 20.0,
      large: 22.0,
      extraLarge: 24.0,
    );
    final spacing = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingSM + 2,
      large: AppConstants.spacingMD,
      extraLarge: AppConstants.spacingMD,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTheme.celebratoryHaloGradient,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tips_and_updates,
              size: iconSize, color: theme.colorScheme.primary),
          SizedBox(width: spacing),
          Flexible(
            child: Text(
              text,
              style: ResponsiveTypography.adjust(
                context,
                theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
