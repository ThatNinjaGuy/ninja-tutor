import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/reading/reading_interface_mixin.dart';
import '../../widgets/common/empty_state.dart';

/// Interactive reading screen with contextual AI features
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({
    super.key,
    this.bookId,
  });

  final String? bookId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> 
    with ReadingInterfaceMixin {

  @override
  Widget build(BuildContext context) {
    final currentBook = ref.watch(currentBookProvider);
    final user = ref.watch(authProvider);

    // Check if user is authenticated
    if (user == null) {
      return _buildLoginPrompt(context);
    }

    // If we have a current book and are in reading mode, show the reading interface from mixin
    if (currentBook != null && isReadingMode) {
      return buildReadingInterface(currentBook);
    }

    // Otherwise, show book selection screen
    final libraryState = ref.watch(unifiedLibraryProvider);
    
    // Show loading state while fetching books
    if (libraryState.isLoadingUserLibrary && libraryState.myBooks.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.selectBookToRead),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppStrings.loadingYourBooks),
            ],
          ),
        ),
      );
    }
    
    // Handle book loading from URL parameter only when needed
    if (widget.bookId != null && libraryState.myBooks.isNotEmpty) {
      try {
        final book = libraryState.myBooks.firstWhere((b) => b.id == widget.bookId);
        
        // Set the book once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(currentBookProvider.notifier).state = book;
            setReadingMode(true);
          }
        });
      } catch (e) {
        // Book not found in user's library
      }
    }

    return _buildSelectBookScreen(context, libraryState);
  }

  Widget _buildSelectBookScreen(BuildContext context, LibraryState libraryState) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.selectBookToRead),
        centerTitle: true,
      ),
      body: libraryState.myBooks.isEmpty
          ? EmptyStateWidget(
              icon: Icons.library_books_outlined,
              title: AppStrings.noBooks,
              subtitle: AppStrings.addBooksFromLibrary,
              actionText: AppStrings.goToLibrary,
              onAction: () => ref.read(navigationProvider.notifier).state = 3,
            )
          : _buildBookList(libraryState.myBooks),
    );
  }

  Widget _buildBookList(List<BookModel> books) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.menu_book,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(book.title),
            subtitle: Text('${book.author} • ${book.subject}'),
            onTap: () {
              ref.read(currentBookProvider.notifier).state = book;
              setReadingMode(true);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reading),
        centerTitle: true,
      ),
      body: EmptyStateWidget(
        icon: Icons.login,
        title: AppStrings.pleaseSignIn,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.reading);
          context.go('/login');
        },
      ),
    );
  }
}
