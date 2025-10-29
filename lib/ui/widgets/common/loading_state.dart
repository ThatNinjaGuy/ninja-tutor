import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';

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

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Indicator(
          indicator: indicator,
          showSpinner: showSpinner,
          progress: progress,
          icon: icon,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
              if (progressLabel != null || progress != null) ...[
                const SizedBox(height: 16),
                _ProgressLabel(
                  progress: progress,
                  label: progressLabel,
                ),
              ],
              if (messages != null && messages!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages!
                      .map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  message,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                const SizedBox(height: 18),
                _TipChip(text: tip!),
              ],
              if (actions != null || onCancel != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (actions != null) actions!,
                    if (actions != null && onCancel != null)
                      const SizedBox(width: 12),
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

    final effectivePadding = padding ?? const EdgeInsets.all(24);

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
        constraints: const BoxConstraints(maxWidth: 560),
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

class _IndicatorState extends State<_Indicator> with SingleTickerProviderStateMixin {
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

    Widget indicator;
    if (widget.indicator != null) {
      indicator = widget.indicator!;
    } else if (widget.progress != null) {
      indicator = SizedBox(
        height: 40,
        width: 40,
        child: CircularProgressIndicator(
          value: widget.progress!.clamp(0.0, 1.0),
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        ),
      );
    } else if (widget.showSpinner) {
      indicator = SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
      );
    } else {
      indicator = Icon(
        widget.icon ?? Icons.auto_awesome,
        size: 32,
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
              padding: const EdgeInsets.all(6),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress?.clamp(0.0, 1.0),
            minHeight: 6,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 6),
          Text(
            '${(progress!.clamp(0.0, 1.0) * 100).round()}% complete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w600,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          Icon(Icons.tips_and_updates, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

