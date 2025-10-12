import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../models/note/note_model.dart';
import '../../widgets/notes/note_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/search_filter_bar.dart';

/// Notes screen for managing highlights and annotations
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  NoteType? _selectedType;
  String? _selectedTag;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider);
    final notes = ref.watch(allNotesProvider);

    // Show login prompt if not authenticated
    if (authUser == null) {
      return _buildLoginPrompt(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notes),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            tooltip: 'More options',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Notes'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Notes'),
              ),
              const PopupMenuItem(
                value: 'organize',
                child: Text('Organize'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.allNotes),
            Tab(text: AppStrings.highlights),
            Tab(text: AppStrings.bookmarks),
            Tab(text: AppStrings.collections),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(context),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotes(context, notes),
                _buildHighlights(context, notes),
                _buildBookmarks(context, notes),
                _buildCollections(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return SearchFilterBar(
      searchHint: 'Search notes...',
      searchQuery: _searchQuery,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
      },
      filterWidgets: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<NoteType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.filter_list),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<NoteType>(
                    value: null,
                    child: Text('All Types', style: TextStyle(fontSize: 14)),
                  ),
                  ...NoteType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getNoteTypeName(type), style: const TextStyle(fontSize: 14)),
                    );
                  }),
                ],
                onChanged: (type) {
                  setState(() => _selectedType = type);
                },
              ),
            ),
            const SizedBox(width: 12),
            FilterChip(
              label: const Text('Favorites', style: TextStyle(fontSize: 12)),
              selected: _showFavoritesOnly,
              onSelected: (value) {
                setState(() => _showFavoritesOnly = value);
              },
              avatar: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.highlight:
        return 'Highlight';
      case NoteType.text:
        return 'Note';
      case NoteType.drawing:
        return 'Drawing';
      case NoteType.bookmark:
        return 'Bookmark';
      case NoteType.question:
        return 'Question';
      case NoteType.summary:
        return 'Summary';
    }
  }

  Widget _buildAllNotes(BuildContext context, AsyncValue<List<NoteModel>> notes) {
    return notes.when(
      data: (noteList) {
        if (noteList.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.sticky_note_2_outlined,
            title: AppStrings.noNotesYet,
            subtitle: AppStrings.startReadingTakeNotes,
          );
        }

        final filteredNotes = _filterNotes(noteList);

        if (filteredNotes.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: AppStrings.noNotesFound,
            subtitle: AppStrings.tryAdjustingFilters,
          );
        }

        return _buildNotesList(filteredNotes);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('${AppStrings.errorLoadingNotes}: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(allNotesProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(BuildContext context, AsyncValue<List<NoteModel>> notes) {
    return notes.when(
      data: (noteList) {
        final highlights = noteList.where((note) => note.isHighlight).toList();
        
        if (highlights.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.highlight_outlined,
            title: AppStrings.noHighlights,
            subtitle: AppStrings.highlightWhileReading,
          );
        }

        final filteredHighlights = _filterNotes(highlights);
        return _buildNotesList(filteredHighlights);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${AppStrings.errorLoadingHighlights}: $error'),
      ),
    );
  }

  Widget _buildBookmarks(BuildContext context, AsyncValue<List<NoteModel>> notes) {
    return notes.when(
      data: (noteList) {
        final bookmarks = noteList.where((note) => note.type == NoteType.bookmark).toList();
        
        if (bookmarks.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.bookmark_outline,
            title: AppStrings.noBookmarks,
            subtitle: AppStrings.bookmarkWhileReading,
          );
        }

        final filteredBookmarks = _filterNotes(bookmarks);
        return _buildNotesList(filteredBookmarks);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${AppStrings.errorLoadingBookmarks}: $error'),
      ),
    );
  }

  Widget _buildCollections(BuildContext context) {
    // Mock collections for now
    return const Center(
      child: Text(AppStrings.collectionsComingSoon),
    );
  }

  Widget _buildNotesList(List<NoteModel> notes) {
    // Group notes by book for better organization
    final notesByBook = <String, List<NoteModel>>{};
    for (final note in notes) {
      notesByBook.putIfAbsent(note.bookId, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: notesByBook.length,
      itemBuilder: (context, index) {
        final bookId = notesByBook.keys.elementAt(index);
        final bookNotes = notesByBook[bookId]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              _getBookTitle(bookId),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${bookNotes.length} notes'),
            children: bookNotes.map((note) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: NoteCard(
                  note: note,
                  onTap: () => _openNote(note),
                  onEdit: () => _editNote(note),
                  onDelete: () => _deleteNote(note),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    var filtered = notes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) =>
          note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered.where((note) => note.type == _selectedType).toList();
    }

    // Apply tag filter
    if (_selectedTag != null) {
      filtered = filtered.where((note) => note.tags.contains(_selectedTag)).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((note) => note.isFavorite).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  String _getBookTitle(String bookId) {
    final libraryState = ref.read(unifiedLibraryProvider);
    
    // Try to find book in user's library first
    try {
      final book = libraryState.myBooks.firstWhere((b) => b.id == bookId);
      return book.title;
    } catch (e) {
      // Not in user's library, try all books
      try {
        final book = libraryState.allBooks.firstWhere((b) => b.id == bookId);
        return book.title;
      } catch (e) {
        // Book not found, return fallback
        return 'Unknown Book';
      }
    }
  }

  void _toggleSearch() {
    // TODO: Implement search toggle
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportNotes();
        break;
      case 'import':
        _importNotes();
        break;
      case 'organize':
        _organizeNotes();
        break;
    }
  }

  void _exportNotes() {
    // TODO: Implement notes export
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Notes'),
        content: const Text('Export functionality will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _importNotes() {
    // TODO: Implement notes import
  }

  void _organizeNotes() {
    // TODO: Implement notes organization
  }

  void _createNote() {
    showDialog(
      context: context,
      builder: (context) => _CreateNoteDialog(),
    );
  }

  void _openNote(NoteModel note) {
    // TODO: Navigate to note detail screen
    // Placeholder: Will navigate to note detail when implemented
  }

  void _editNote(NoteModel note) {
    // TODO: Edit note
    // Placeholder: Will show edit dialog when implemented
  }

  void _deleteNote(NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete note - will be implemented with API integration
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notes)),
      body: EmptyStateWidget(
        icon: Icons.sticky_note_2_outlined,
        title: AppStrings.pleaseLogin,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.notes);
          context.go('/login');
        },
      ),
    );
  }
}

/// Dialog for creating new notes
class _CreateNoteDialog extends StatefulWidget {
  @override
  State<_CreateNoteDialog> createState() => __CreateNoteDialogState();
}

class __CreateNoteDialogState extends State<_CreateNoteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  NoteType _selectedType = NoteType.text;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Note'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Enter note title',
              ),
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter note content',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Type selection
            DropdownButtonFormField<NoteType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: NoteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getNoteTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createNote,
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.text:
        return 'Text Note';
      case NoteType.highlight:
        return 'Highlight';
      case NoteType.bookmark:
        return 'Bookmark';
      case NoteType.question:
        return 'Question';
      case NoteType.summary:
        return 'Summary';
      case NoteType.drawing:
        return 'Drawing';
    }
  }

  void _createNote() {
    if (_contentController.text.trim().isEmpty) {
      return;
    }

    // TODO: Create actual note - will be implemented with API integration
    Navigator.pop(context);
  }
}
