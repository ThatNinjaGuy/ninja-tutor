import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/reading_ai_provider.dart';

/// AI Chat Panel for intelligent reading assistance
class AiChatPanel extends ConsumerStatefulWidget {
  final String bookId;
  final int currentPage;
  final String? selectedText;
  final VoidCallback onClose;
  final bool isFullscreen;

  const AiChatPanel({
    super.key,
    required this.bookId,
    required this.currentPage,
    this.selectedText,
    required this.onClose,
    this.isFullscreen = false,
  });

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _selectedTextScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // State for selected text pill
  bool _isPillExpanded = false;  // Collapsed by default (shows "Source")
  String? _previousSelectedText;  // Track if selected text has changed
  bool _isAtBottom = true;  // Track if scrolled to bottom

  @override
  void initState() {
    super.initState();
    _previousSelectedText = widget.selectedText;
    
    // Listen to scroll position
    _scrollController.addListener(_onScroll);
    
    // Update context when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readingAiProvider.notifier).updateContext(
        page: widget.currentPage,
        selectedText: widget.selectedText,
        bookId: widget.bookId,
      );
    });
  }
  
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50.0;
    
    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });
    }
  }

  @override
  void didUpdateWidget(AiChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update context if page or selection changes
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.selectedText != widget.selectedText) {
      ref.read(readingAiProvider.notifier).updateContext(
        page: widget.currentPage,
        selectedText: widget.selectedText,
        bookId: widget.bookId,
      );
      
      // If selected text changed, keep pill collapsed
      if (oldWidget.selectedText != widget.selectedText) {
        setState(() {
          _isPillExpanded = false;
          _previousSelectedText = widget.selectedText;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _selectedTextScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        // Update bottom state after scrolling
        setState(() {
          _isAtBottom = true;
        });
      }
    });
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();
    ref.read(readingAiProvider.notifier).askQuestion(message, widget.bookId);
    
    // Keep the pill collapsed after sending question
    if (_isPillExpanded) {
      setState(() {
        _isPillExpanded = false;
      });
    }
    
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  void _handleQuickAction(String action) {
    final text = widget.selectedText ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select some text first')),
      );
      return;
    }

    // Build the prompt based on the action
    String prompt;
    switch (action) {
      case 'define':
        prompt = 'Define the term or phrase: "$text"';
        break;
      case 'explain':
        prompt = 'Explain this text: "$text"';
        break;
      case 'summarize':
        prompt = 'Summarize this text: "$text"';
        break;
      default:
        prompt = 'Explain this text: "$text"';
    }

    // Set the text in the controller and send the message
    _textController.text = prompt;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiState = ref.watch(readingAiProvider);

    return Material(
      elevation: widget.isFullscreen ? 12 : 8,
      borderRadius: BorderRadius.circular(widget.isFullscreen ? 16 : 12),
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(widget.isFullscreen ? 16 : 12),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(theme),

                // Selected text pill
                if (widget.selectedText != null)
                  _buildSelectedTextPill(theme),

                // Error message
                if (aiState.error != null)
                  _buildErrorBanner(theme, aiState.error!),

                // Message list
                Expanded(
                  child: aiState.messages.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildMessageList(theme, aiState),
                ),

                // Quick actions (only show at bottom when text is selected)
                if (widget.selectedText != null && _isAtBottom)
                  _buildQuickActions(theme, aiState),

                // Input field
                _buildInputField(theme, aiState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI Reading Assistant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(readingAiProvider.notifier).clearHistory();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear conversation',
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTextPill(ThemeData theme) {
    final selectedText = widget.selectedText ?? '';
    final fontSize = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
    final lineHeightMultiplier = theme.textTheme.bodyMedium?.height ?? 1.4;
    final maxHeight = fontSize * lineHeightMultiplier * 5;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isPillExpanded = !_isPillExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.text_fields,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPillExpanded ? 'Selected Text' : 'Source',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isPillExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isPillExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        controller: _selectedTextScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _selectedTextScrollController,
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            selectedText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(readingAiProvider.notifier).clearError();
            },
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ReadingAiState aiState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickActionButton(
                theme,
                'Define',
                Icons.search,
                () => _handleQuickAction('define'),
                isEnabled: !aiState.isLoading,
              ),
              _buildQuickActionButton(
                theme,
                'Explain',
                Icons.lightbulb_outline,
                () => _handleQuickAction('explain'),
                isEnabled: !aiState.isLoading,
              ),
              _buildQuickActionButton(
                theme,
                'Summarize',
                Icons.summarize,
                () => _handleQuickAction('summarize'),
                isEnabled: !aiState.isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    required bool isEnabled,
  }) {
    return OutlinedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
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
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask me anything!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I can help you understand your reading material.\nTry selecting text and using quick actions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme, ReadingAiState aiState) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          ...aiState.messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;
            final isUser = message.role == 'user';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: 16,
                      child: Icon(
                        Icons.psychology,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary,
                  radius: 16,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
          }),
          // Show loading indicator at the end
          if (aiState.isLoading)
            _buildLoadingIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 16,
            child: Icon(
              Icons.psychology,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gathering context...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(ThemeData theme, ReadingAiState aiState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: widget.isFullscreen,
              decoration: InputDecoration(
                hintText: 'Ask a question about your reading...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              enabled: !aiState.isLoading,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: aiState.isLoading ? null : _sendMessage,
            icon: Icon(
              Icons.send,
              color: aiState.isLoading
                  ? theme.colorScheme.onSurface.withOpacity(0.3)
                  : theme.colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

