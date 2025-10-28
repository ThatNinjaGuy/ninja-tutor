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

  ReadingAiState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.selectedText,
    this.bookId,
  });

  ReadingAiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    int? currentPage,
    String? selectedText,
    String? bookId,
    bool clearError = false,
    bool clearSelectedText = false,
  }) {
    return ReadingAiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      selectedText: clearSelectedText ? null : (selectedText ?? this.selectedText),
      bookId: bookId ?? this.bookId,
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
    state = state.copyWith(
      currentPage: page,
      selectedText: selectedText,
      bookId: bookId,
      clearSelectedText: selectedText == null,
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
      // Call API with conversation history
      final response = await _apiService.askReadingQuestion(
        question: question,
        bookId: bookId,
        currentPage: state.currentPage,
        selectedText: state.selectedText,
        conversationHistory: state.conversationHistory,
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
        clearSelectedText: true, // Clear selection after answering
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
}

/// Provider for the reading AI state
final readingAiProvider = StateNotifierProvider<ReadingAiNotifier, ReadingAiState>(
  (ref) => ReadingAiNotifier(ApiService()),
);

