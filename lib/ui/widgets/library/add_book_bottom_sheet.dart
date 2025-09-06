import 'package:flutter/material.dart';
import 'book_upload_dialog.dart';

/// Bottom sheet for adding books with different options
class AddBookBottomSheet extends StatelessWidget {
  const AddBookBottomSheet({super.key});

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
          _buildOption(
            context,
            icon: Icons.upload_file,
            title: 'Upload PDF/EPUB',
            subtitle: 'Add from your device',
            onTap: () {
              Navigator.pop(context);
              _showUploadDialog(context);
            },
          ),
          _buildOption(
            context,
            icon: Icons.camera_alt,
            title: 'Scan Book',
            subtitle: 'Use camera to scan pages',
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Scanning feature coming soon!');
            },
          ),
          _buildOption(
            context,
            icon: Icons.link,
            title: 'Add by URL',
            subtitle: 'Import from web link',
            onTap: () {
              Navigator.pop(context);
              _showComingSoon(context, 'URL import feature coming soon!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BookUploadDialog(),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
