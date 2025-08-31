import 'package:flutter/material.dart';

import '../../../models/note/note_model.dart';

/// Note filter widget for filtering notes
class NoteFilter extends StatelessWidget {
  const NoteFilter({
    super.key,
    this.selectedType,
    this.selectedTag,
    this.showFavoritesOnly = false,
    this.onTypeChanged,
    this.onTagChanged,
    this.onFavoritesToggled,
  });

  final NoteType? selectedType;
  final String? selectedTag;
  final bool showFavoritesOnly;
  final ValueChanged<NoteType?>? onTypeChanged;
  final ValueChanged<String?>? onTagChanged;
  final ValueChanged<bool>? onFavoritesToggled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<NoteType>(
            value: selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              const DropdownMenuItem<NoteType>(
                value: null,
                child: Text('All Types'),
              ),
              ...NoteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getNoteTypeName(type)),
                );
              }),
            ],
            onChanged: onTypeChanged,
          ),
        ),
        const SizedBox(width: 16),
        
        FilterChip(
          label: const Text('Favorites'),
          selected: showFavoritesOnly,
          onSelected: onFavoritesToggled,
          avatar: Icon(
            showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            size: 18,
          ),
        ),
      ],
    );
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.highlight:
        return 'Highlight';
      case NoteType.text:
        return 'Note';
      case NoteType.drawing:
        return 'Drawing';
      case NoteType.bookmark:
        return 'Bookmark';
      case NoteType.question:
        return 'Question';
      case NoteType.summary:
        return 'Summary';
    }
  }
}

