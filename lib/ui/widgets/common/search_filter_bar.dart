import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_layout.dart';

/// Reusable search and filter bar component that handles responsive layout
/// On wide screens: displays search and filters in a single row
/// On smaller screens: stacks search and filters vertically
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchHint,
    this.searchQuery = '',
    this.onSearchChanged,
    this.filterWidgets = const [],
    this.showFilters = true,
    this.compactActions = const <Widget>[],
  });

  final String searchHint;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> filterWidgets;
  final bool showFilters;
  final List<Widget> compactActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = ResponsiveBreakpoints.isSmall(context);
    final shouldShowInlineFilters =
        showFilters && filterWidgets.isNotEmpty && !isSmall;

    final horizontalPadding = context.responsiveValue(
      small: AppConstants.defaultPadding,
      medium: AppConstants.defaultPadding,
      large: AppConstants.largePadding,
      extraLarge: AppConstants.largePadding,
    );
    final verticalPadding = context.responsiveValue(
      small: AppConstants.spacingXS,
      medium: AppConstants.spacingXS,
      large: AppConstants.spacingSM,
      extraLarge: AppConstants.spacingMD,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.responsiveMaxContentWidth),
            child: shouldShowInlineFilters
                ? _buildInlineLayout(context)
                : _buildCompactInlineRow(context),
          ),
        ),
      ),
    );
  }

  /// Single-line layout for medium+ screens (search + filters in one row)
  Widget _buildInlineLayout(BuildContext context) {
    final gap = context.responsiveGutter;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSearchField(context)),
        SizedBox(width: gap),
        Expanded(
          child: filterWidgets.length == 1
              ? filterWidgets.first
              : Row(
                  children: [
                    for (int i = 0; i < filterWidgets.length; i++) ...[
                      Expanded(child: filterWidgets[i]),
                      if (i < filterWidgets.length - 1)
                        SizedBox(
                            width: math.max(AppConstants.spacingSM, gap / 2)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Compact single-row layout: search field + icon actions
  Widget _buildCompactInlineRow(BuildContext context) {
    final gap = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingMD,
      large: AppConstants.spacingLG,
      extraLarge: AppConstants.spacingLG,
    );

    return Row(
      children: [
        Expanded(child: _buildSearchField(context)),
        if (compactActions.isNotEmpty) ...[
          SizedBox(width: gap),
          Row(children: [
            ...compactActions.expand((w) sync* {
              yield w;
              if (w != compactActions.last) {
                yield SizedBox(width: AppConstants.spacingSM);
              }
            })
          ])
        ]
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = context.responsiveValue(
      small: 14.0,
      medium: 16.0,
      large: 16.0,
      extraLarge: 18.0,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: searchQuery.isNotEmpty
            ? [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.06),
                  blurRadius: context.responsiveValue(
                    small: 10,
                    medium: 12,
                    large: 16,
                    extraLarge: 20,
                  ),
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => onSearchChanged?.call(''),
                  icon: const Icon(Icons.clear),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              small: 14,
              medium: 16,
              large: 18,
              extraLarge: 20,
            ),
            vertical: context.responsiveValue(
              small: 8,
              medium: 10,
              large: 12,
              extraLarge: 14,
            ),
          ),
          isDense: true,
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}

/// Compact filter row that wraps to multiple lines on small screens
class CompactFilterRow extends StatelessWidget {
  const CompactFilterRow({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingMD,
      large: AppConstants.spacingLG,
      extraLarge: AppConstants.spacingLG,
    );

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: children,
    );
  }
}

/// Single line filter row with responsive sizing
class ResponsiveFilterRow extends StatelessWidget {
  const ResponsiveFilterRow({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = context.responsiveValue(
      small: AppConstants.spacingSM,
      medium: AppConstants.spacingMD,
      large: AppConstants.spacingLG,
      extraLarge: AppConstants.spacingLG,
    );

    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}
