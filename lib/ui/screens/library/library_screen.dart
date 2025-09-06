import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/books_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/library/book_filter.dart';

/// Library screen for managing books and content
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubject;
  String? _selectedGrade;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksApiProvider);
    final user = ref.watch(authProvider);

    // Show login prompt if user is not authenticated
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please log in to access your library',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your books and reading progress will be saved across devices',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: _addBook,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Books'),
            Tab(text: 'Subjects'),
            Tab(text: 'Recent'),
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
                _buildMyBooks(context, books),
                _buildSubjects(context, books),
                _buildRecent(context, books),
              ],
            ),
          ),
        ],
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
              hintText: 'Search books...',
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
              // Trigger search on the backend
              if (value.isNotEmpty) {
                ref.read(bookSearchProvider.notifier).searchBooks(value);
              } else {
                ref.read(bookSearchProvider.notifier).clearSearch();
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filters
          BookFilter(
            selectedSubject: _selectedSubject,
            selectedGrade: _selectedGrade,
            onSubjectChanged: (subject) {
              setState(() {
                _selectedSubject = subject;
              });
              // Reload books with new filter
              ref.read(booksApiProvider.notifier).loadBooks(
                subject: _selectedSubject?.isEmpty == true ? null : _selectedSubject,
                grade: _selectedGrade?.isEmpty == true ? null : _selectedGrade,
              );
            },
            onGradeChanged: (grade) {
              setState(() {
                _selectedGrade = grade;
              });
              // Reload books with new filter
              ref.read(booksApiProvider.notifier).loadBooks(
                subject: _selectedSubject?.isEmpty == true ? null : _selectedSubject,
                grade: _selectedGrade?.isEmpty == true ? null : _selectedGrade,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooks(BuildContext context, AsyncValue<List<BookModel>> books) {
    // Use search results if there's a search query, otherwise use the main books list
    final searchResults = ref.watch(bookSearchProvider);
    final booksToShow = _searchQuery.isNotEmpty ? searchResults : books;
    
    return booksToShow.when(
      data: (bookList) {
        if (bookList.isEmpty && _searchQuery.isEmpty) {
          return _buildEmptyState(
            'No Books in Library',
            'Add your first book to get started with learning!',
            Icons.library_books_outlined,
          );
        }

        final filteredBooks = _searchQuery.isNotEmpty ? bookList : _filterBooks(bookList);

        if (filteredBooks.isEmpty) {
          return _buildEmptyState(
            _searchQuery.isNotEmpty ? 'No Books Found' : 'No Matching Books',
            _searchQuery.isNotEmpty ? 'Try a different search term' : 'Try adjusting your filters',
            Icons.search_off,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredBooks.length,
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return BookCard(
              book: book,
              onTap: () => _openBook(book),
              onLongPress: () => _showBookOptions(book),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Error loading books: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(booksApiProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjects(BuildContext context, AsyncValue<List<BookModel>> books) {
    return books.when(
      data: (bookList) {
        if (bookList.isEmpty) {
          return _buildEmptyState(
            'No Subjects Available',
            'Add books to see them organized by subject',
            Icons.category_outlined,
          );
        }

        // Group books by subject
        final subjectMap = <String, List<BookModel>>{};
        for (final book in bookList) {
          subjectMap.putIfAbsent(book.subject, () => []).add(book);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: subjectMap.length,
          itemBuilder: (context, index) {
            final subject = subjectMap.keys.elementAt(index);
            final subjectBooks = subjectMap[subject]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(subject).withOpacity(0.1),
                  child: Icon(
                    _getSubjectIcon(subject),
                    color: _getSubjectColor(subject),
                  ),
                ),
                title: Text(
                  subject,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${subjectBooks.length} books'),
                children: [
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      itemCount: subjectBooks.length,
                      itemBuilder: (context, bookIndex) {
                        final book = subjectBooks[bookIndex];
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 16),
                          child: BookCard(
                            book: book,
                            onTap: () => _openBook(book),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading subjects: $error'),
      ),
    );
  }

  Widget _buildRecent(BuildContext context, AsyncValue<List<BookModel>> books) {
    return books.when(
      data: (bookList) {
        final recentBooks = bookList
            .where((book) => book.lastReadAt != null)
            .toList()
          ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));

        if (recentBooks.isEmpty) {
          return _buildEmptyState(
            'No Recent Activity',
            'Start reading to see your recent books here',
            Icons.history,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: recentBooks.length,
          itemBuilder: (context, index) {
            final book = recentBooks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(book.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${book.author} • ${book.subject}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: book.progressPercentage,
                      backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ],
                ),
                trailing: Text(
                  _formatLastRead(book.lastReadAt!),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                onTap: () => _openBook(book),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading recent books: $error'),
      ),
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
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _addBook,
              child: const Text('Add Book'),
            ),
          ],
        ),
      ),
    );
  }

  List<BookModel> _filterBooks(List<BookModel> books) {
    var filtered = books;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) =>
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.subject.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply subject filter
    if (_selectedSubject != null) {
      filtered = filtered.where((book) => book.subject == _selectedSubject).toList();
    }

    // Apply grade filter
    if (_selectedGrade != null) {
      filtered = filtered.where((book) => book.grade == _selectedGrade).toList();
    }

    return filtered;
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppConstants.desktopBreakpoint) return 6;
    if (width >= AppConstants.tabletBreakpoint) return 4;
    return 2;
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Colors.blue;
      case 'science':
      case 'biology':
      case 'chemistry':
      case 'physics':
        return Colors.green;
      case 'english':
      case 'literature':
        return Colors.purple;
      case 'history':
      case 'social studies':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate;
      case 'science':
      case 'biology':
      case 'chemistry':
      case 'physics':
        return Icons.science;
      case 'english':
      case 'literature':
        return Icons.translate;
      case 'history':
      case 'social studies':
        return Icons.public;
      default:
        return Icons.book;
    }
  }

  String _formatLastRead(DateTime lastRead) {
    final now = DateTime.now();
    final difference = now.difference(lastRead);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _addBook() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AddBookBottomSheet(),
    );
  }

  void _openBook(BookModel book) {
    // Navigate to reading screen with this book
    ref.read(currentBookProvider.notifier).state = book;
    // You might want to navigate to reading screen here
  }

  void _showBookOptions(BookModel book) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BookOptionsBottomSheet(book: book),
    );
  }
}

/// Bottom sheet for adding books
class _AddBookBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddBookBottomSheet> createState() => _AddBookBottomSheetState();
}

class _AddBookBottomSheetState extends ConsumerState<_AddBookBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Book',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload PDF/EPUB'),
            subtitle: const Text('Add from your device'),
            onTap: () {
              Navigator.pop(context);
              _showUploadDialog();
            },
          ),

          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Scan Book'),
            subtitle: const Text('Use camera to scan pages'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement scanning
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning feature coming soon!')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Add by URL'),
            subtitle: const Text('Import from web link'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement URL import
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL import feature coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _BookUploadDialog(),
    );
  }

}

/// Dialog for uploading books with metadata
class _BookUploadDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BookUploadDialog> createState() => _BookUploadDialogState();
}

class _BookUploadDialogState extends ConsumerState<_BookUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedSubject = 'General';
  String _selectedGrade = '10';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final List<String> _subjects = [
    'General',
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'Computer Science',
    'Art',
    'Music',
  ];

  final List<Map<String, String>> _grades = [
    {'value': '1', 'display': 'Grade 1'},
    {'value': '2', 'display': 'Grade 2'},
    {'value': '3', 'display': 'Grade 3'},
    {'value': '4', 'display': 'Grade 4'},
    {'value': '5', 'display': 'Grade 5'},
    {'value': '6', 'display': 'Grade 6'},
    {'value': '7', 'display': 'Grade 7'},
    {'value': '8', 'display': 'Grade 8'},
    {'value': '9', 'display': 'Grade 9'},
    {'value': '10', 'display': 'Grade 10'},
    {'value': '11', 'display': 'Grade 11'},
    {'value': '12', 'display': 'Grade 12'},
    {'value': 'College', 'display': 'College'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Book'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File picker
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.description : Icons.upload_file,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile?.name ?? 'No file selected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: const Text('Choose File'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a book title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Author
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject and Grade
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        decoration: const InputDecoration(
                          labelText: 'Grade',
                          border: OutlineInputBorder(),
                        ),
                        items: _grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade['value'],
                            child: Text(grade['display']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(),
                    hintText: 'physics, textbook, advanced',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadBook,
          child: _isUploading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'txt', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        // Auto-fill title from filename if title is empty
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.first.name
              .replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to upload books'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Prepare metadata
      final metadata = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim().isEmpty 
            ? 'Unknown Author' 
            : _authorController.text.trim(),
        'subject': _selectedSubject,
        'grade': _selectedGrade,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'tags': _tagsController.text.trim(),
      };

      // Upload the book
      await ref.read(booksApiProvider.notifier).uploadBookFromBytes(
        _selectedFile!.bytes!,
        _selectedFile!.name,
        metadata,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book "${_titleController.text}" uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

/// Bottom sheet for book options
class _BookOptionsBottomSheet extends StatelessWidget {
  const _BookOptionsBottomSheet({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            book.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Book Details'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show book details
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Metadata'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Edit book metadata
            },
          ),

          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Share book
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove from Library'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Book'),
        content: Text('Are you sure you want to remove "${book.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete book
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
