import 'package:flutter/material.dart';

/// Book filter widget for filtering library content
class BookFilter extends StatelessWidget {
  const BookFilter({
    super.key,
    this.selectedSubject,
    this.selectedGrade,
    this.onSubjectChanged,
    this.onGradeChanged,
  });

  final String? selectedSubject;
  final String? selectedGrade;
  final ValueChanged<String?>? onSubjectChanged;
  final ValueChanged<String?>? onGradeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.subject),
            ),
            items: _getSubjects().map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(subject),
              );
            }).toList(),
            onChanged: onSubjectChanged,
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedGrade,
            decoration: const InputDecoration(
              labelText: 'Grade',
              prefixIcon: Icon(Icons.school),
            ),
            items: _getGrades().map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text(grade),
              );
            }).toList(),
            onChanged: onGradeChanged,
          ),
        ),
      ],
    );
  }

  List<String> _getSubjects() {
    return [
      'Mathematics',
      'Science',
      'English',
      'History',
      'Geography',
      'Computer Science',
      'Art',
      'Music',
    ];
  }

  List<String> _getGrades() {
    return [
      'Grade 1',
      'Grade 2',
      'Grade 3',
      'Grade 4',
      'Grade 5',
      'Grade 6',
      'Grade 7',
      'Grade 8',
      'Grade 9',
      'Grade 10',
      'Grade 11',
      'Grade 12',
      'College',
    ];
  }
}

