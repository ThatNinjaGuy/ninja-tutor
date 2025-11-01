import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/note/highlight_model.dart';
import '../../../services/api/api_service.dart';

/// Highlights Panel for viewing and managing highlights
class HighlightsPanel extends ConsumerStatefulWidget {
  final String bookId;
  final int Function() getCurrentPage;
  final VoidCallback onClose;
  final Function(int page)? onPageNavigate;

  const HighlightsPanel({
    super.key,
    required this.bookId,
    required this.getCurrentPage,
    required this.onClose,
    this.onPageNavigate,
  });

  @override
  ConsumerState<HighlightsPanel> createState() => _HighlightsPanelState();
}

class _HighlightsPanelState extends ConsumerState<HighlightsPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showCurrentPageOnly = true;
  List<HighlightModel> _highlights = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  @override
  void didUpdateWidget(HighlightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _loadHighlights();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final highlights = await ApiService().getHighlightsForBook(widget.bookId);
      if (!mounted) return;

      setState(() {
        _highlights = highlights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHighlight(HighlightModel highlight) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await ApiService().deleteHighlight(highlight.id);

      if (mounted) {
        setState(() {
          _highlights = _highlights.where((h) => h.id != highlight.id).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Highlight deleted successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete highlight: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: (_) {},
      onPointerMove: (_) {},
      onPointerUp: (_) {},
      onPointerSignal: (_) {},
      behavior: HitTestBehavior.opaque,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme),

                // Highlights list - scrollable middle section
                Expanded(
                  child: _buildHighlightsList(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final currentPage = widget.getCurrentPage();
    final displayedHighlights = _showCurrentPageOnly
        ? _highlights.where((h) => h.pageNumber == currentPage).toList()
        : _highlights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.highlight,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Highlights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${displayedHighlights.length} ${displayedHighlights.length == 1 ? 'highlight' : 'highlights'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter toggle
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text('Page $currentPage'),
                icon: const Icon(Icons.filter_alt, size: 16),
              ),
              const ButtonSegment(
                value: false,
                label: Text('All Highlights'),
                icon: Icon(Icons.list, size: 16),
              ),
            ],
            selected: {_showCurrentPageOnly},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _showCurrentPageOnly = selection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    final currentPage = widget.getCurrentPage();
    final displayedHighlights = _showCurrentPageOnly
        ? _highlights.where((h) => h.pageNumber == currentPage).toList()
        : _highlights;

    if (displayedHighlights.isEmpty) {
      return _buildEmptyState(theme);
    }

    final sortedHighlights = List<HighlightModel>.from(displayedHighlights)
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedHighlights.map((highlight) {
          return _buildHighlightItem(theme, highlight);
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.highlight_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _showCurrentPageOnly
                  ? 'No highlights on this page'
                  : 'No highlights yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select text and tap the highlight button to mark important passages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHighlights,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(ThemeData theme, HighlightModel highlight) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final formattedDate = highlight.createdAt != null
        ? dateFormat.format(highlight.createdAt!)
        : 'Unknown date';

    // Get color for the highlight
    final colorName = highlight.color.toLowerCase();
    Color highlightColor;
    switch (colorName) {
      case 'yellow':
        highlightColor = Colors.yellow.shade300;
        break;
      case 'green':
        highlightColor = Colors.green.shade300;
        break;
      case 'blue':
        highlightColor = Colors.blue.shade300;
        break;
      case 'pink':
        highlightColor = Colors.pink.shade300;
        break;
      case 'orange':
        highlightColor = Colors.orange.shade300;
        break;
      case 'purple':
        highlightColor = Colors.purple.shade300;
        break;
      default:
        highlightColor = Colors.green.shade300;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          widget.onPageNavigate?.call(highlight.pageNumber);
          widget.onClose();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: highlightColor.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Page ${highlight.pageNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete button
                  IconButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _showDeleteConfirmation(highlight),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Delete highlight',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Highlighted text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlightColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: highlightColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  highlight.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Date
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(HighlightModel highlight) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Highlight'),
        content: const Text('Are you sure you want to delete this highlight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteHighlight(highlight);
    }
  }
}

