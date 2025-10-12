import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

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
  });

  final String searchHint;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> filterWidgets;
  final bool showFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use single-line layout on wide screens (tablet/desktop)
    final isWideScreen = screenWidth >= AppConstants.wideScreenBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: isWideScreen && showFilters && filterWidgets.isNotEmpty
          ? _buildSingleLineLayout()
          : _buildStackedLayout(),
    );
  }

  /// Single-line layout for wide screens (search + filters in one row)
  Widget _buildSingleLineLayout() {
    return Row(
      children: [
        // Search bar (flexible, takes remaining space)
        Expanded(
          flex: 2,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 16),
        // Filters (flexible, shared space)
        // Simply render filterWidgets directly - they should handle their own layout
        Expanded(
          flex: 3,
          child: filterWidgets.length == 1 
              ? filterWidgets[0]
              : Row(
                  children: [
                    for (int i = 0; i < filterWidgets.length; i++) ...[
                      Expanded(child: filterWidgets[i]),
                      if (i < filterWidgets.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Stacked layout for smaller screens (search above, filters below)
  Widget _buildStackedLayout() {
    return Column(
      children: [
        // Search bar (always full width)
        TextField(
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => onSearchChanged?.call(''),
                    icon: const Icon(Icons.clear),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            isDense: true,
          ),
          onChanged: onSearchChanged,
        ),
        
        // Filters (if any)
        if (showFilters && filterWidgets.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...filterWidgets,
        ],
      ],
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
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
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

