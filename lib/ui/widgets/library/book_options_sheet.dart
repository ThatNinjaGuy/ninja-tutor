import 'package:flutter/material.dart';
import '../../../models/content/book_model.dart';

/// Bottom sheet for book options and actions
class BookOptionsSheet extends StatelessWidget {
  const BookOptionsSheet({super.key, required this.book});

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
          _buildOption(Icons.info_outline, 'Book Details', () {
            Navigator.pop(context);
            _showComingSoon(context, 'Book details feature coming soon!');
          }),
          _buildOption(Icons.edit, 'Edit Metadata', () {
            Navigator.pop(context);
            _showComingSoon(context, 'Edit metadata feature coming soon!');
          }),
          _buildOption(Icons.share, 'Share', () {
            Navigator.pop(context);
            _showComingSoon(context, 'Share feature coming soon!');
          }),
          _buildOption(
            Icons.delete_outline, 
            'Remove from Library', 
            () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
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
              _showComingSoon(context, 'Delete feature coming soon!');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
