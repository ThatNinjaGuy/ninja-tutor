import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;

class ReadingControlsOverlay extends ConsumerStatefulWidget {
  final String bookId;
  final String selectedText;
  final int pageNumber;
  final Map<String, dynamic>? position;
  final VoidCallback? onClose;

  const ReadingControlsOverlay({
    Key? key,
    required this.bookId,
    required this.selectedText,
    required this.pageNumber,
    this.position,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<ReadingControlsOverlay> createState() => _ReadingControlsOverlayState();
}

class _ReadingControlsOverlayState extends ConsumerState<ReadingControlsOverlay> {
  bool _isHighlightMode = false;
  String _selectedColor = 'yellow';

  @override
  Widget build(BuildContext context) {
    if (widget.selectedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected text preview
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                widget.selectedText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Highlight buttons
                _buildHighlightButton('yellow', Colors.yellow),
                _buildHighlightButton('green', Colors.green),
                _buildHighlightButton('blue', Colors.blue),
                
                // Divider
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                
                // Note button
                _buildActionButton(
                  icon: Icons.note_add,
                  tooltip: 'Add Note',
                  onTap: () => _addNote(),
                ),
                
                // Define button
                _buildActionButton(
                  icon: Icons.search,
                  tooltip: 'Define Word',
                  onTap: () => _defineWord(),
                ),
                
                // AI button
                _buildActionButton(
                  icon: Icons.psychology,
                  tooltip: 'Ask AI',
                  onTap: () => _askAI(),
                ),
                
                // Close button
                _buildActionButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onTap: widget.onClose,
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildHighlightButton(String colorName, Color color) {
    return GestureDetector(
      onTap: () => _createHighlight(colorName),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _selectedColor == colorName ? color : Colors.grey[300]!,
            width: _selectedColor == colorName ? 2 : 1,
          ),
        ),
        child: Icon(
          Icons.highlight,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _createHighlight(String color) {
    // Send highlight command to PDF.js
    _sendMessageToPdf('createHighlight', {
      'text': widget.selectedText,
      'page': widget.pageNumber,
      'color': color,
      'position': widget.position,
    });
    
    // Close overlay
    widget.onClose?.call();
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Highlighted with $color'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addNote() {
    // Send message to parent Flutter window to trigger note creation
    _sendMessageToFlutter({
      'type': 'createNoteFromSelection',
      'selectedText': widget.selectedText,
      'page': widget.pageNumber,
      'position': widget.position,
    });
    
    // Close overlay
    widget.onClose?.call();
  }
  
  void _sendMessageToFlutter(Map<String, dynamic> data) {
    // Send message to parent Flutter window
    html.window.parent?.postMessage(data, '*');
  }

  void _defineWord() {
    // Import the AI provider at the top if not already done
    if (widget.selectedText.isEmpty) return;
    
    // Call quick action through parent callback
    // This will be handled by the reading interface to open AI panel
    widget.onClose?.call();
    
    // Show snackbar to indicate action is triggered
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening definition for "${widget.selectedText.substring(0, widget.selectedText.length > 20 ? 20 : widget.selectedText.length)}..."'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _askAI() {
    // Close overlay and let parent handle opening AI panel with selected text
    widget.onClose?.call();
    
    if (widget.selectedText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening AI assistant...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _sendMessageToPdf(String type, Map<String, dynamic> data) {
    final message = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...data,
    };
    
    // Send message to PDF.js iframe
    html.window.postMessage(message, '*');
  }
}
