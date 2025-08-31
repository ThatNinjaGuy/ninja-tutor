import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/note/note_model.dart';
import '../../widgets/notes/note_card.dart';
import '../../widgets/notes/note_filter.dart';

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
    final theme = Theme.of(context);
    final notes = ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
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
            Tab(text: 'All Notes'),
            Tab(text: 'Highlights'),
            Tab(text: 'Bookmarks'),
            Tab(text: 'Collections'),
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
    final theme = Theme.of(context);

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
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filters
          NoteFilter(
            selectedType: _selectedType,
            selectedTag: _selectedTag,
            showFavoritesOnly: _showFavoritesOnly,
            onTypeChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
            onTagChanged: (tag) {
              setState(() {
                _selectedTag = tag;
              });
            },
            onFavoritesToggled: (favoritesOnly) {
              setState(() {
                _showFavoritesOnly = favoritesOnly;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotes(BuildContext context, AsyncValue<List<NoteModel>> notes) {
    return notes.when(
      data: (noteList) {
        if (noteList.isEmpty) {
          return _buildEmptyState(
            'No Notes Yet',
            'Start reading and take notes to see them here',
            Icons.sticky_note_2_outlined,
          );
        }

        final filteredNotes = _filterNotes(noteList);

        if (filteredNotes.isEmpty) {
          return _buildEmptyState(
            'No Notes Found',
            'Try adjusting your search or filters',
            Icons.search_off,
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
            Text('Error loading notes: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(allNotesProvider),
              child: const Text('Retry'),
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
          return _buildEmptyState(
            'No Highlights',
            'Highlight text while reading to see them here',
            Icons.highlight_outlined,
          );
        }

        final filteredHighlights = _filterNotes(highlights);
        return _buildNotesList(filteredHighlights);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading highlights: $error'),
      ),
    );
  }

  Widget _buildBookmarks(BuildContext context, AsyncValue<List<NoteModel>> notes) {
    return notes.when(
      data: (noteList) {
        final bookmarks = noteList.where((note) => note.type == NoteType.bookmark).toList();
        
        if (bookmarks.isEmpty) {
          return _buildEmptyState(
            'No Bookmarks',
            'Bookmark pages while reading to see them here',
            Icons.bookmark_outline,
          );
        }

        final filteredBookmarks = _filterNotes(bookmarks);
        return _buildNotesList(filteredBookmarks);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading bookmarks: $error'),
      ),
    );
  }

  Widget _buildCollections(BuildContext context) {
    // Mock collections for now
    return const Center(
      child: Text('Collections feature coming soon!'),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.4),
            ),
            const SizedBox(height: 16),

            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
    // TODO: Get actual book title from books provider
    return 'Book $bookId';
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
    print('Opening note: ${note.id}');
  }

  void _editNote(NoteModel note) {
    // TODO: Edit note
    print('Editing note: ${note.id}');
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
              // TODO: Delete note
              print('Deleting note: ${note.id}');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

    // TODO: Create actual note
    print('Creating note: ${_contentController.text}');
    Navigator.pop(context);
  }
}
