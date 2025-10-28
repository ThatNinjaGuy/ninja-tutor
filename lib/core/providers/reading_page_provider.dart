import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for tracking the current page being read in a book
class ReadingPageState {
  final String bookId;
  final int currentPage;
  
  const ReadingPageState({
    required this.bookId,
    required this.currentPage,
  });
  
  /// CopyWith method for creating a new state with updated values
  ReadingPageState copyWith({
    String? bookId,
    int? currentPage,
  }) {
    return ReadingPageState(
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for managing the reading page state
class ReadingPageNotifier extends StateNotifier<ReadingPageState> {
  ReadingPageNotifier() : super(const ReadingPageState(bookId: '', currentPage: 1));
  
  /// Update the current page for a specific book
  void updatePage(String bookId, int page) {
    state = ReadingPageState(bookId: bookId, currentPage: page);
  }
  
  /// Reset the state
  void reset() {
    state = const ReadingPageState(bookId: '', currentPage: 1);
  }
}

/// Provider for the reading page state
final readingPageProvider = StateNotifierProvider<ReadingPageNotifier, ReadingPageState>((ref) {
  return ReadingPageNotifier();
});

