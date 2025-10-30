import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_service.dart';

/// Message in the reading AI chat
class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  ChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// State for the reading AI chat interface
class ReadingAiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final String? selectedText;
  final String? bookId;
  final Map<int, String> pageTextCache;

  ReadingAiState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.selectedText,
    this.bookId,
    this.pageTextCache = const {},
  });

  ReadingAiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? selectedText,
    String? bookId,
    Map<int, String>? pageTextCache,
    bool clearError = false,
    bool clearSelectedText = false,
    bool clearPageTextCache = false,
  }) {
    return ReadingAiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      selectedText: clearSelectedText ? null : (selectedText ?? this.selectedText),
      bookId: bookId ?? this.bookId,
      pageTextCache: clearPageTextCache
          ? const {}
          : (pageTextCache ?? this.pageTextCache),
    );
  }

  /// Get conversation history in format expected by API
  List<Map<String, String>> get conversationHistory {
    return messages.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();
  }
}

/// Notifier for managing reading AI state
class ReadingAiNotifier extends StateNotifier<ReadingAiState> {
  final ApiService _apiService;

  ReadingAiNotifier(this._apiService) : super(ReadingAiState());

  /// Update the current reading context (page and selected text)
  void updateContext({
    required int page,
    String? selectedText,
    String? bookId,
  }) {
    final bool bookChanged =
        bookId != null && bookId.isNotEmpty && bookId != state.bookId;

    state = state.copyWith(
      currentPage: page,
      selectedText: selectedText,
      bookId: bookId,
      clearSelectedText: selectedText == null,
      clearPageTextCache: bookChanged,
    );
  }

  /// Ask a question about the current reading
  Future<void> askQuestion(String question, String bookId) async {
    if (question.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      content: question,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final pageContext = await _loadPageContext(bookId, state.currentPage);

      // Call API with conversation history
      final response = await _apiService.askReadingQuestion(
        question: question,
        bookId: bookId,
        currentPage: state.currentPage,
        selectedText: state.selectedText,
        conversationHistory: state.conversationHistory,
        currentPageText: pageContext['current_page_text'],
        previousPageText: pageContext['previous_page_text'],
        nextPageText: pageContext['next_page_text'],
      );

      // Add AI response
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response['answer'] ?? 'Sorry, I could not generate an answer.',
        timestamp: DateTime.now(),
        metadata: {
          'confidence': response['confidence'],
          'context_range': response['context_range'],
          'has_selected_text': response['has_selected_text'],
        },
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get answer: ${e.toString()}',
      );
    }
  }


  /// Clear the conversation history
  void clearHistory() {
    state = state.copyWith(
      messages: [],
      error: null,
    );
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear selected text
  void clearSelectedText() {
    state = state.copyWith(clearSelectedText: true);
  }

  Future<Map<String, String>> _loadPageContext(String bookId, int currentPage) async {
    final Map<String, String> contextTexts = {
      'previous_page_text': '',
      'current_page_text': '',
      'next_page_text': '',
    };

    final List<int> pagesToFetch = [];
    final Map<int, String> cacheUpdates = {};

    void checkPage(String key, int? pageNumber) {
      if (pageNumber == null || pageNumber < 1) {
        return;
      }

      final cached = state.pageTextCache[pageNumber];
      if (cached != null) {
        contextTexts[key] = cached;
      } else {
        pagesToFetch.add(pageNumber);
      }
    }

    checkPage('previous_page_text', currentPage > 1 ? currentPage - 1 : null);
    checkPage('current_page_text', currentPage);
    checkPage('next_page_text', currentPage + 1);

    if (pagesToFetch.isNotEmpty) {
      try {
        final response = await _apiService.getMultiplePageContent(bookId, pagesToFetch);
        final pages = response['pages'] as Map<String, dynamic>? ?? {};
        
        for (final entry in pages.entries) {
          final pageNumber = int.tryParse(entry.key);
          if (pageNumber == null) continue;
          
          final content = (entry.value as String?)?.trim() ?? '';
          cacheUpdates[pageNumber] = content;
          
          if (pageNumber == currentPage - 1) {
            contextTexts['previous_page_text'] = content;
          } else if (pageNumber == currentPage) {
            contextTexts['current_page_text'] = content;
          } else if (pageNumber == currentPage + 1) {
            contextTexts['next_page_text'] = content;
          }
        }
      } catch (_) {
        for (final pageNum in pagesToFetch) {
          cacheUpdates[pageNum] = '';
          if (pageNum == currentPage - 1) {
            contextTexts['previous_page_text'] = '';
          } else if (pageNum == currentPage) {
            contextTexts['current_page_text'] = '';
          } else if (pageNum == currentPage + 1) {
            contextTexts['next_page_text'] = '';
          }
        }
      }
    }

    if (cacheUpdates.isNotEmpty) {
      state = state.copyWith(
        pageTextCache: {
          ...state.pageTextCache,
          ...cacheUpdates,
        },
      );
    }

    return contextTexts;
  }
}

/// Provider for the reading AI state
final readingAiProvider = StateNotifierProvider<ReadingAiNotifier, ReadingAiState>(
  (ref) => ReadingAiNotifier(ApiService()),
);

