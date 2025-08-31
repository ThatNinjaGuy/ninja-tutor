import 'package:flutter/material.dart';

/// Quiz session widget for taking quizzes
class QuizSession extends StatefulWidget {
  const QuizSession({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends State<QuizSession> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Session ${widget.sessionId}'),
      ),
      body: const Center(
        child: Text(
          'Quiz session implementation will be added here\n\n'
          'Features:\n'
          '• Question display and navigation\n'
          '• Answer selection and validation\n'
          '• Timer and progress tracking\n'
          '• Immediate feedback\n'
          '• Results and analysis',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

