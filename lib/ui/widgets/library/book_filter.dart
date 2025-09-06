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
            items: _getGrades().map((gradeEntry) {
              return DropdownMenuItem(
                value: gradeEntry['value'],
                child: Text(gradeEntry['display']!),
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

  List<Map<String, String>> _getGrades() {
    return [
      {'value': '1', 'display': 'Grade 1'},
      {'value': '2', 'display': 'Grade 2'},
      {'value': '3', 'display': 'Grade 3'},
      {'value': '4', 'display': 'Grade 4'},
      {'value': '5', 'display': 'Grade 5'},
      {'value': '6', 'display': 'Grade 6'},
      {'value': '7', 'display': 'Grade 7'},
      {'value': '8', 'display': 'Grade 8'},
      {'value': '9', 'display': 'Grade 9'},
      {'value': '10', 'display': 'Grade 10'},
      {'value': '11', 'display': 'Grade 11'},
      {'value': '12', 'display': 'Grade 12'},
      {'value': 'College', 'display': 'College'},
    ];
  }
}

