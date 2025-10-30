import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/content/book_model.dart';
import '../../widgets/reading/reading_interface_mixin.dart';

/// Full-screen reader that shows only the PDF/reading UI
class ReaderFullScreen extends ConsumerStatefulWidget {
  const ReaderFullScreen({super.key, required this.bookId, this.initialPage});

  final String bookId;
  final int? initialPage; // optional page override

  @override
  ConsumerState<ReaderFullScreen> createState() => _ReaderFullScreenState();
}

class _ReaderFullScreenState extends ConsumerState<ReaderFullScreen>
    with ReadingInterfaceMixin {
  BookModel? _book;

  @override
  void initState() {
    super.initState();
    // Ensure user's books are loaded to locate the target book
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final currentBook = ref.watch(currentBookProvider);

    // Try to find the book once library is available
    if (_book == null && libraryState.myBooks.isNotEmpty) {
      try {
        final found =
            libraryState.myBooks.firstWhere((b) => b.id == widget.bookId);
        _book = found;
        // Respect an already-set current book (e.g., from Notes/Bookmarks specifying a page)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final existing = ref.read(currentBookProvider);
          final desiredPage = widget.initialPage;
          BookModel withPage(BookModel b) {
            if (desiredPage == null) return b;
            final now = DateTime.now();
            return b.copyWith(
              progress: b.progress?.copyWith(currentPage: desiredPage) ??
                  ReadingProgress(
                    bookId: b.id,
                    currentPage: desiredPage,
                    lastReadAt: now,
                    startedAt: now,
                  ),
            );
          }

          if (existing == null || existing.id != found.id) {
            ref.read(currentBookProvider.notifier).state = withPage(found);
          } else if (desiredPage != null && existing.progress?.currentPage != desiredPage) {
            ref.read(currentBookProvider.notifier).state = withPage(existing);
          }
          setReadingMode(true);
        });
      } catch (_) {
        // keep _book null if not found
      }
    }

    if ((_book != null || currentBook != null) && isReadingMode) {
      // Prefer the already-provided currentBook (may carry overridden page)
      return buildReadingInterface(currentBook?.id == widget.bookId ? currentBook! : _book!);
    }

    // Loading or book not found UI
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.selectBookToRead)),
      body: Center(
        child: libraryState.isLoadingUserLibrary
            ? const CircularProgressIndicator()
            : const Text('Book not found in your library'),
      ),
    );
  }
}


