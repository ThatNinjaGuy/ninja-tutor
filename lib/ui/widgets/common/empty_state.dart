import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_layout.dart';

/// Reusable empty state widget for displaying empty content states
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = context.responsiveValue(
      small: 56.0,
      medium: 64.0,
      large: 72.0,
      extraLarge: 80.0,
    );
    final gap = context.responsiveValue(
      small: AppConstants.spacingMD,
      medium: AppConstants.spacingLG,
      large: AppConstants.spacingXL,
      extraLarge: AppConstants.spacingXL,
    );
    final maxWidth = context.responsiveValue(
      small: 420.0,
      medium: 520.0,
      large: 640.0,
      extraLarge: 720.0,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.pageHorizontalPadding,
          vertical: gap,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.onBackground.withOpacity(0.4),
              ),
              SizedBox(height: gap * 0.75),
              Text(
                title,
                style: ResponsiveTypography.adjust(
                  context,
                  theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      theme.textTheme.titleLarge ??
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: gap * 0.5),
              Text(
                subtitle,
                style: _subtitleStyle(theme, context),
                textAlign: TextAlign.center,
              ),
              if (actionText != null && onAction != null) ...[
                SizedBox(height: gap),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    Icons.arrow_forward,
                    size: context.responsiveValue(
                      small: 18.0,
                      medium: 20.0,
                      large: 22.0,
                      extraLarge: 24.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveValue(
                        small: 18.0,
                        medium: 22.0,
                        large: 26.0,
                        extraLarge: 30.0,
                      ),
                      vertical: context.responsiveValue(
                        small: 10.0,
                        medium: 12.0,
                        large: 14.0,
                        extraLarge: 16.0,
                      ),
                    ),
                  ),
                  label: Text(actionText!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _subtitleStyle(ThemeData theme, BuildContext context) {
    final base = theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onBackground.withOpacity(0.7),
          height: 1.4,
        ) ??
        TextStyle(
          color: theme.colorScheme.onBackground.withOpacity(0.7),
        );
    return ResponsiveTypography.adjust(context, base);
  }
}
