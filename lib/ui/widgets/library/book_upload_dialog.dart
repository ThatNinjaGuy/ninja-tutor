import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/book_categories.dart';

/// Dialog for uploading books with metadata
class BookUploadDialog extends ConsumerStatefulWidget {
  const BookUploadDialog({super.key});

  @override
  ConsumerState<BookUploadDialog> createState() => _BookUploadDialogState();
}

class _BookUploadDialogState extends ConsumerState<BookUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedCategory = BookCategories.getDefault();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Book'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilePicker(),
                const SizedBox(height: 16),
                _buildTextField(_titleController, 'Book Title *', isRequired: true),
                const SizedBox(height: 16),
                _buildTextField(_authorController, 'Author'),
                const SizedBox(height: 16),
                _buildCategoryField(),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Description', maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(_tagsController, 'Tags (comma-separated)', 
                    hintText: 'physics, textbook, advanced'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadBook,
          child: _isUploading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Upload'),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            _selectedFile != null ? Icons.description : Icons.upload_file,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFile?.name ?? 'No file selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickFile,
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, 
      {bool isRequired = false, int maxLines = 1, String? hintText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: hintText,
      ),
      maxLines: maxLines,
      validator: isRequired ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a ${label.toLowerCase().replaceAll(' *', '')}';
        }
        return null;
      } : null,
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: BookCategories.getSelectable().map((category) => DropdownMenuItem(
        value: category,
        child: Text(category),
      )).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'txt', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        // Auto-fill title from filename if empty
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.first.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        _showSnackBar('Please select a file to upload', Colors.red);
      }
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      _showSnackBar('Please log in to upload books', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final metadata = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim().isEmpty ? 'Unknown Author' : _authorController.text.trim(),
        'subject': _selectedCategory,
        'grade': 'General', // Using "General" for backward compatibility with backend
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'tags': _tagsController.text.trim(),
      };

      await ref.read(unifiedLibraryProvider.notifier).uploadBookFromBytes(
        _selectedFile!.bytes!,
        _selectedFile!.name,
        metadata,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Book "${_titleController.text}" uploaded successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
