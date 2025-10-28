import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/note/note_model.dart';
import '../../../core/providers/notes_provider.dart';
import '../../../core/providers/reading_page_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'note_creation_dialog.dart';

/// Notes Panel for managing reading notes
class NotesPanel extends ConsumerStatefulWidget {
  final String bookId;
  final int Function() getCurrentPage;  // Changed to callback
  final VoidCallback onClose;
  final String? selectedText;  // Optional: pre-selected text from PDF
  final Function(String noteId)? onNoteClicked;  // Callback when a note is clicked

  const NotesPanel({
    super.key,
    required this.bookId,
    required this.getCurrentPage,
    required this.onClose,
    this.selectedText,
    this.onNoteClicked,
  });

  @override
  ConsumerState<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends ConsumerState<NotesPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  bool _showCurrentPageOnly = true;

  @override
  void initState() {
    super.initState();
    // Load notes when panel first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔷 NotesPanel initState: loading notes for ${widget.bookId}');
      ref.read(notesProvider.notifier).loadNotes(widget.bookId);
    });
  }

  @override
  void didUpdateWidget(NotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload notes if book changes
    if (oldWidget.bookId != widget.bookId) {
      print('🔷 NotesPanel: Book changed from ${oldWidget.bookId} to ${widget.bookId}');
      ref.read(notesProvider.notifier).loadNotes(widget.bookId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteNote(NoteModel note) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final success = await ref.read(notesProvider.notifier).deleteNote(note.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted successfully'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete note'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showNoteCreationDialog() async {
    if (_isProcessing) return;
    
    // Get current page at dialog time - use provider or fallback to callback
    final pageState = ref.read(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.getCurrentPage();
    await showDialog(
      context: context,
      builder: (context) => NoteCreationDialog(
        pageNumber: currentPage,
        selectedText: widget.selectedText,  // Pass selected text from PDF
        onSave: (String content, String? title, String? selectedText) async {
          setState(() => _isProcessing = true);
          
          try {
            final note = await ref.read(notesProvider.notifier).createNote(
              bookId: widget.bookId,
              pageNumber: currentPage,
              content: content,
              title: title,
              selectedText: selectedText, // Pass selected text to provider
            );

            if (mounted) {
              if (note != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note created successfully'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to create note'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          } finally {
            if (mounted) {
              setState(() => _isProcessing = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesState = ref.watch(notesProvider);

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
                _buildHeader(theme, notesState),

                // Notes list - scrollable middle section
                Expanded(
                  child: _buildNotesList(theme, notesState),
                ),

                // Add note section - fixed at bottom
                _buildAddNoteSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, NotesState notesState) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.getCurrentPage();
    final displayedNotes = _showCurrentPageOnly
        ? notesState.getNotesForPage(currentPage)
        : notesState.allNotes;
    
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
                Icons.note,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${displayedNotes.length} ${displayedNotes.length == 1 ? 'note' : 'notes'}',
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
                label: Text('All Notes'),
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

  Widget _buildNotesList(ThemeData theme, NotesState notesState) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.getCurrentPage();
    final displayedNotes = _showCurrentPageOnly
        ? notesState.getNotesForPage(currentPage)
        : notesState.allNotes;

    if (notesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (displayedNotes.isEmpty) {
      return _buildEmptyState(theme);
    }

    final sortedNotes = List<NoteModel>.from(displayedNotes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedNotes.map((note) {
          return _buildNoteItem(theme, note);
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
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _showCurrentPageOnly 
                  ? 'No notes on this page'
                  : 'No notes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Note" to create your first note',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(ThemeData theme, NoteModel note) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.getCurrentPage();
    final isCurrentPage = note.pageNumber == currentPage;
    final dateFormat = DateFormat('MMM d, HH:mm');

    return InkWell(
      onTap: () => widget.onNoteClicked?.call(note.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentPage
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPage
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Page ${note.pageNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormat.format(note.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isProcessing ? null : () => _deleteNote(note),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  tooltip: 'Delete note',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (note.title != null && note.title!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.title!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            // Display selected text (context from PDF) if available
            if (note.selectedText != null && note.selectedText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Selected text',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.selectedText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              note.content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddNoteSection(ThemeData theme) {
    // Watch reading page provider for dynamic updates
    final pageState = ref.watch(readingPageProvider);
    final currentPage = pageState.bookId == widget.bookId ? pageState.currentPage : widget.getCurrentPage();
    final currentPageNotesCount = ref.watch(notesProvider).getNotesCountForPage(currentPage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page $currentPage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currentPageNotesCount ${currentPageNotesCount == 1 ? 'note' : 'notes'} on this page',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _showNoteCreationDialog,
            icon: _isProcessing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : const Icon(Icons.add, size: 20),
            label: Text(_isProcessing ? 'Processing...' : 'Add Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
