import 'package:flutter/material.dart';

import '../../../models/content/book_model.dart';

/// Main reading viewer widget for displaying book content
class ReadingViewer extends StatefulWidget {
  const ReadingViewer({
    super.key,
    required this.book,
    this.onTextSelected,
    this.onDefinitionRequest,
  });

  final BookModel book;
  final Function(String text, Offset position)? onTextSelected;
  final Function(String word)? onDefinitionRequest;

  @override
  State<ReadingViewer> createState() => _ReadingViewerState();
}

class _ReadingViewerState extends State<ReadingViewer> {
  @override
  Widget build(BuildContext context) {
    // Placeholder implementation
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Reading Viewer for: ${widget.book.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Text(
                'PDF/EPUB viewer will be implemented here\n\n'
                'Features:\n'
                '• Text selection and highlighting\n'
                '• Contextual AI definitions\n'
                '• Note-taking integration\n'
                '• Progress tracking\n'
                '• Responsive layouts',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
