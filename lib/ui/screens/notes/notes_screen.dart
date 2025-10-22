import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../models/content/book_model.dart';
import '../../../models/note/note_model.dart';
import '../../widgets/notes/note_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/search_filter_bar.dart';
import '../../widgets/common/profile_menu_button.dart';

/// Combined notes and bookmarks provider that aggregates data from all books
/// Only fetches when user is authenticated
final combinedNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  // Wait for auth to be ready
  final authUser = ref.watch(authProvider);
  
  // Return empty list if not authenticated
  if (authUser == null) {
    debugPrint('⚠️ No authenticated user, skipping notes/bookmarks fetch');
    return [];
  }
  
  debugPrint('📚 Auth ready, fetching all notes and bookmarks for user: ${authUser.id}');
  
  final apiService = ref.watch(apiServiceProvider);
  final allItems = <NoteModel>[];
  
  try {
    // Fetch all notes for user in one call
    debugPrint('🔄 Calling GET /notes/all...');
    final allNotes = await apiService.getAllUserNotes();
    debugPrint('✅ Fetched ${allNotes.length} notes');
    allItems.addAll(allNotes);
  } catch (e) {
    debugPrint('⚠️ Failed to load notes: $e');
  }
  
  try {
    // Fetch all bookmarks for user in one call
    debugPrint('🔄 Calling GET /bookmarks/all...');
    final bookmarksData = await apiService.getAllUserBookmarks();
    debugPrint('✅ Fetched ${bookmarksData.length} bookmarks');
    
    // Convert bookmarks to NoteModel format for display
    for (final bookmarkData in bookmarksData) {
      final bookmarkNote = NoteModel(
        id: bookmarkData['id'] as String,
        bookId: bookmarkData['book_id'] as String,
        pageNumber: bookmarkData['page_number'] as int,
        type: NoteType.bookmark,
        content: bookmarkData['note'] as String? ?? 'Bookmark on page ${bookmarkData['page_number']}',
        title: null,
        tags: const [],
        createdAt: DateTime.parse(bookmarkData['created_at'] as String),
        updatedAt: DateTime.parse(bookmarkData['created_at'] as String),
        position: const NotePosition(
          x: 0.0,
          y: 0.0,
        ),
        style: const NoteStyle(
          color: '#2196F3',
          opacity: 1.0,
          fontSize: 14.0,
          fontFamily: 'Inter',
          isBold: false,
          isItalic: false,
        ),
        isFavorite: false,
      );
      allItems.add(bookmarkNote);
    }
  } catch (e) {
    debugPrint('⚠️ Failed to load bookmarks: $e');
  }
  
  debugPrint('📊 Total items fetched: ${allItems.length} (${allItems.where((n) => n.type != NoteType.bookmark).length} notes, ${allItems.where((n) => n.type == NoteType.bookmark).length} bookmarks)');
  return allItems;
});

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
    _tabController = TabController(length: 2, vsync: this);
    
    // Load My Books for notes screen (needed to display book titles)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider);
    final notesAsync = ref.watch(combinedNotesProvider);

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
          const ProfileMenuButton(currentRoute: AppRoutes.notes),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.allNotes),
            Tab(text: AppStrings.bookmarks),
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
                _buildAllNotes(context, notesAsync),
                _buildBookmarks(context, notesAsync),
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

        return _buildNotesList(filteredNotes, label: 'notes');
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
              onPressed: () => ref.refresh(combinedNotesProvider),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
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
        return _buildNotesList(filteredBookmarks, label: 'bookmarks');
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${AppStrings.errorLoadingBookmarks}: $error'),
      ),
    );
  }

  Widget _buildNotesList(List<NoteModel> notes, {String label = 'items'}) {
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
        
        // Use the provided label (e.g., 'notes' or 'bookmarks')
        final itemCount = bookNotes.length;
        // Convert plural to singular for single items
        String itemLabel = label;
        if (itemCount == 1) {
          if (label == 'notes') {
            itemLabel = 'note';
          } else if (label == 'bookmarks') {
            itemLabel = 'bookmark';
          }
        }
        
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
            subtitle: Text('$itemCount $itemLabel'),
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

  void _openNote(NoteModel note) async {
    // Navigate to reading screen with the book and page
    final libraryState = ref.read(unifiedLibraryProvider);
    
    try {
      // Find the book in user's library
      final book = libraryState.myBooks.firstWhere((b) => b.id == note.bookId);
      
      // Update the book's current page to match the note/bookmark page
      final now = DateTime.now();
      final updatedBook = book.copyWith(
        progress: book.progress?.copyWith(currentPage: note.pageNumber) ?? 
                 ReadingProgress(
                   bookId: note.bookId,
                   currentPage: note.pageNumber,
                   lastReadAt: now,
                   startedAt: now,
                 ),
      );
      
      // Set the book as current book
      ref.read(currentBookProvider.notifier).state = updatedBook;
      
      // Navigate to reading screen
      context.go('/reading/book/${note.bookId}');
      
      // Switch to reading tab
      ref.read(navigationProvider.notifier).state = 1;
    } catch (e) {
      // Book not found in library
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book not found in your library'),
          ),
        );
      }
    }
  }

  void _editNote(NoteModel note) {
    // TODO: Edit note
    // Placeholder: Will show edit dialog when implemented
  }

  void _deleteNote(NoteModel note) {
    final isBookmark = note.type == NoteType.bookmark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBookmark ? 'Delete Bookmark' : 'Delete Note'),
        content: Text('Are you sure you want to delete this ${isBookmark ? 'bookmark' : 'note'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(apiServiceProvider);
                
                // Delete based on type
                if (isBookmark) {
                  await apiService.deleteBookmark(note.id);
                } else {
                  await apiService.deleteNote(note.id);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${isBookmark ? 'Bookmark' : 'Note'} deleted successfully'),
                    ),
                  );
                  // Refresh the notes list
                  ref.refresh(combinedNotesProvider);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete ${isBookmark ? 'bookmark' : 'note'}: $e')),
                  );
                }
              }
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
