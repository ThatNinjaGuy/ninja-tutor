import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'quiz_model.g.dart';

/// Quiz model for practice assessments
@HiveType(typeId: 30)
@JsonSerializable()
class QuizModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  @JsonKey(name: 'book_id')
  final String bookId;
  
  @HiveField(4)
  final String subject;
  
  @HiveField(5)
  @JsonKey(name: 'page_range')
  final List<int> pageRange; // [startPage, endPage]
  
  @HiveField(6)
  final List<QuestionModel> questions;
  
  @HiveField(7)
  final QuizSettings settings;
  
  @HiveField(8)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(9)
  final QuizType type;
  
  @HiveField(10)
  final DifficultyLevel difficulty;
  
  @HiveField(11)
  final List<String> tags;
  
  @HiveField(12)
  final bool isAdaptive; // AI adjusts difficulty based on performance
  
  const QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.bookId,
    required this.subject,
    required this.pageRange,
    required this.questions,
    required this.settings,
    required this.createdAt,
    required this.type,
    required this.difficulty,
    this.tags = const [],
    this.isAdaptive = false,
  });
  
  factory QuizModel.fromJson(Map<String, dynamic> json) => 
      _$QuizModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuizModelToJson(this);
  
  /// Get total number of questions
  int get totalQuestions => questions.length;
  
  /// Get estimated completion time in minutes
  int get estimatedTime {
    const baseTimePerQuestion = 2; // minutes
    return totalQuestions * baseTimePerQuestion;
  }
  
  /// Get maximum possible score
  int get maxScore => questions.fold(0, (sum, q) => sum + q.points);
  
  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? bookId,
    String? subject,
    List<int>? pageRange,
    List<QuestionModel>? questions,
    QuizSettings? settings,
    DateTime? createdAt,
    QuizType? type,
    DifficultyLevel? difficulty,
    List<String>? tags,
    bool? isAdaptive,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bookId: bookId ?? this.bookId,
      subject: subject ?? this.subject,
      pageRange: pageRange ?? this.pageRange,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isAdaptive: isAdaptive ?? this.isAdaptive,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        bookId,
        subject,
        pageRange,
        questions,
        settings,
        createdAt,
        type,
        difficulty,
        tags,
        isAdaptive,
      ];
}

/// Types of quizzes
@HiveType(typeId: 31)
enum QuizType {
  @HiveField(0)
  practice,
  
  @HiveField(1)
  assessment,
  
  @HiveField(2)
  review,
  
  @HiveField(3)
  adaptive,
  
  @HiveField(4)
  timed,
  
  @HiveField(5)
  final_,
}

/// Difficulty levels (reusing from book_model for consistency)
@HiveType(typeId: 32)
enum DifficultyLevel {
  @HiveField(0)
  beginner,
  
  @HiveField(1)
  easy,
  
  @HiveField(2)
  medium,
  
  @HiveField(3)
  hard,
  
  @HiveField(4)
  expert,
}

/// Quiz configuration settings
@HiveType(typeId: 33)
@JsonSerializable()
class QuizSettings extends Equatable {
  @HiveField(0)
  final int? timeLimit; // in minutes, null for unlimited
  
  @HiveField(1)
  @JsonKey(name: 'shuffle_questions')
  final bool shuffleQuestions;
  
  @HiveField(2)
  @JsonKey(name: 'shuffle_options')
  final bool shuffleAnswers;
  
  @HiveField(3)
  final bool showFeedback; // Immediate feedback after each question
  
  @HiveField(4)
  @JsonKey(name: 'allow_retakes')
  final bool allowReview; // Can review answers before submitting
  
  @HiveField(5)
  @JsonKey(name: 'show_results_immediately')
  final bool showCorrectAnswers; // Show correct answers after completion
  
  @HiveField(6)
  final int maxAttempts;
  
  @HiveField(7)
  final double passingScore; // 0-1, percentage needed to pass
  
  const QuizSettings({
    this.timeLimit,
    this.shuffleQuestions = false,
    this.shuffleAnswers = false,
    this.showFeedback = true,
    this.allowReview = true,
    this.showCorrectAnswers = true,
    this.maxAttempts = 3,
    this.passingScore = 0.7,
  });
  
  factory QuizSettings.fromJson(Map<String, dynamic> json) => 
      _$QuizSettingsFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuizSettingsToJson(this);
  
  /// Check if quiz is timed
  bool get isTimed => timeLimit != null;
  
  QuizSettings copyWith({
    int? timeLimit,
    bool? shuffleQuestions,
    bool? shuffleAnswers,
    bool? showFeedback,
    bool? allowReview,
    bool? showCorrectAnswers,
    int? maxAttempts,
    double? passingScore,
  }) {
    return QuizSettings(
      timeLimit: timeLimit ?? this.timeLimit,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleAnswers: shuffleAnswers ?? this.shuffleAnswers,
      showFeedback: showFeedback ?? this.showFeedback,
      allowReview: allowReview ?? this.allowReview,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      passingScore: passingScore ?? this.passingScore,
    );
  }
  
  @override
  List<Object?> get props => [
        timeLimit,
        shuffleQuestions,
        shuffleAnswers,
        showFeedback,
        allowReview,
        showCorrectAnswers,
        maxAttempts,
        passingScore,
      ];
}

/// Individual question model
@HiveType(typeId: 34)
@JsonSerializable()
class QuestionModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'question_text')
  final String question;
  
  @HiveField(2)
  final QuestionType type;
  
  @HiveField(3)
  final List<AnswerOption> options; // For MCQ
  
  @HiveField(4)
  @JsonKey(name: 'correct_answer')
  final String? correctAnswer; // For short answer/essay
  
  @HiveField(5)
  @JsonKey(name: 'correct_answers', defaultValue: [])
  final List<String> correctAnswers; // For multiple correct answers
  
  @HiveField(6)
  final String? explanation;
  
  @HiveField(7)
  final int points;
  
  @HiveField(8)
  final DifficultyLevel difficulty;
  
  @HiveField(9)
  @JsonKey(defaultValue: [])
  final List<String> hints;
  
  @HiveField(10)
  @JsonKey(name: 'image_url')
  final String? imageUrl; // Question image
  
  @HiveField(11)
  @JsonKey(name: 'audio_url')
  final String? audioUrl; // Question audio
  
  @HiveField(12)
  @JsonKey(defaultValue: [])
  final List<String> tags; // Learning objectives
  
  const QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctAnswer,
    this.correctAnswers = const [],
    this.explanation,
    this.points = 1,
    this.difficulty = DifficultyLevel.medium,
    this.hints = const [],
    this.imageUrl,
    this.audioUrl,
    this.tags = const [],
  });
  
  factory QuestionModel.fromJson(Map<String, dynamic> json) => 
      _$QuestionModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);
  
  /// Check if question has multiple correct answers
  bool get hasMultipleCorrectAnswers => correctAnswers.length > 1;
  
  /// Check if question has media content
  bool get hasMedia => imageUrl != null || audioUrl != null;
  
  /// Check if question has hints available
  bool get hasHints => hints.isNotEmpty;
  
  QuestionModel copyWith({
    String? id,
    String? question,
    QuestionType? type,
    List<AnswerOption>? options,
    String? correctAnswer,
    List<String>? correctAnswers,
    String? explanation,
    int? points,
    DifficultyLevel? difficulty,
    List<String>? hints,
    String? imageUrl,
    String? audioUrl,
    List<String>? tags,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      difficulty: difficulty ?? this.difficulty,
      hints: hints ?? this.hints,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        question,
        type,
        options,
        correctAnswer,
        correctAnswers,
        explanation,
        points,
        difficulty,
        hints,
        imageUrl,
        audioUrl,
        tags,
      ];
}

/// Types of questions
@HiveType(typeId: 35)
enum QuestionType {
  @HiveField(0)
  multipleChoice,
  
  @HiveField(1)
  multipleSelect,
  
  @HiveField(2)
  trueFalse,
  
  @HiveField(3)
  shortAnswer,
  
  @HiveField(4)
  essay,
  
  @HiveField(5)
  fillInTheBlank,
  
  @HiveField(6)
  matching,
  
  @HiveField(7)
  ordering,
  
  @HiveField(8)
  audio,
  
  @HiveField(9)
  video,
}

/// Answer option for multiple choice questions
@HiveType(typeId: 36)
@JsonSerializable()
class AnswerOption extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String text;
  
  @HiveField(2)
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  
  @HiveField(3)
  final String? explanation; // Why this answer is correct/incorrect
  
  @HiveField(4)
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
    this.imageUrl,
  });
  
  factory AnswerOption.fromJson(Map<String, dynamic> json) => 
      _$AnswerOptionFromJson(json);
  
  Map<String, dynamic> toJson() => _$AnswerOptionToJson(this);
  
  /// Check if option has an image
  bool get hasImage => imageUrl != null;
  
  AnswerOption copyWith({
    String? id,
    String? text,
    bool? isCorrect,
    String? explanation,
    String? imageUrl,
  }) {
    return AnswerOption(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  
  @override
  List<Object?> get props => [id, text, isCorrect, explanation, imageUrl];
}

/// Quiz attempt/session result
@HiveType(typeId: 37)
@JsonSerializable()
class QuizResult extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'quiz_id')
  final String quizId;
  
  @HiveField(2)
  @JsonKey(name: 'user_id')
  final String userId;
  
  @HiveField(3)
  @JsonKey(name: 'question_results', defaultValue: [])
  final List<QuestionResult> questionResults;
  
  @HiveField(4)
  @JsonKey(name: 'total_score')
  final int totalScore;
  
  @HiveField(5)
  @JsonKey(name: 'max_score')
  final int maxScore;
  
  @HiveField(6)
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  
  @HiveField(7)
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  
  @HiveField(8)
  @JsonKey(name: 'is_passed')
  final bool isPassed;
  
  @HiveField(9)
  @JsonKey(name: 'attempt_number')
  final int attemptNumber;
  
  @HiveField(10)
  final Map<String, dynamic> analytics; // Performance analytics
  
  // Backend provides these directly
  @HiveField(11)
  @JsonKey(name: 'percentage')
  final double? percentageValue;
  
  @HiveField(12)
  @JsonKey(name: 'correct_answers')
  final int? correctAnswersCount;
  
  @HiveField(13)
  @JsonKey(name: 'incorrect_answers')
  final int? incorrectAnswersCount;
  
  @HiveField(14)
  @JsonKey(name: 'time_taken')
  final int? timeTakenMinutes;
  
  const QuizResult({
    required this.id,
    required this.quizId,
    required this.userId,
    this.questionResults = const [],
    required this.totalScore,
    required this.maxScore,
    this.startedAt,
    required this.completedAt,
    required this.isPassed,
    this.attemptNumber = 1,
    this.analytics = const {},
    this.percentageValue,
    this.correctAnswersCount,
    this.incorrectAnswersCount,
    this.timeTakenMinutes,
  });
  
  factory QuizResult.fromJson(Map<String, dynamic> json) => 
      _$QuizResultFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuizResultToJson(this);
  
  /// Calculate percentage score (use backend value if available, otherwise calculate)
  double get percentage => percentageValue ?? (maxScore > 0 ? totalScore / maxScore : 0.0);
  
  /// Calculate completion time in minutes (use backend value if available, otherwise calculate)
  int get completionTimeMinutes => timeTakenMinutes ?? 
      (startedAt != null ? completedAt.difference(startedAt!).inMinutes : 0);
  
  /// Get number of correct answers (use backend value if available, otherwise calculate)
  int get correctAnswers => correctAnswersCount ?? 
      questionResults.where((q) => q.isCorrect).length;
  
  /// Get number of incorrect answers (use backend value if available, otherwise calculate)
  int get incorrectAnswers => incorrectAnswersCount ?? 
      questionResults.where((q) => !q.isCorrect).length;
  
  QuizResult copyWith({
    String? id,
    String? quizId,
    String? userId,
    List<QuestionResult>? questionResults,
    int? totalScore,
    int? maxScore,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isPassed,
    int? attemptNumber,
    Map<String, dynamic>? analytics,
    double? percentageValue,
    int? correctAnswersCount,
    int? incorrectAnswersCount,
    int? timeTakenMinutes,
  }) {
    return QuizResult(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      questionResults: questionResults ?? this.questionResults,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isPassed: isPassed ?? this.isPassed,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      analytics: analytics ?? this.analytics,
      percentageValue: percentageValue ?? this.percentageValue,
      correctAnswersCount: correctAnswersCount ?? this.correctAnswersCount,
      incorrectAnswersCount: incorrectAnswersCount ?? this.incorrectAnswersCount,
      timeTakenMinutes: timeTakenMinutes ?? this.timeTakenMinutes,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        quizId,
        userId,
        questionResults,
        totalScore,
        maxScore,
        startedAt,
        completedAt,
        isPassed,
        attemptNumber,
        analytics,
        percentageValue,
        correctAnswersCount,
        incorrectAnswersCount,
        timeTakenMinutes,
      ];
}

/// Lightweight quiz summary from backend (for listing quizzes)
@JsonSerializable()
class QuizSummary extends Equatable {
  @JsonKey(name: 'quiz_id')
  final String quizId;
  
  @JsonKey(name: 'book_id')
  final String bookId;
  
  @JsonKey(name: 'book_title')
  final String bookTitle;
  
  final String title;
  final String subject;
  final String difficulty;
  
  @JsonKey(name: 'question_count')
  final int questionCount;
  
  @JsonKey(name: 'total_attempts')
  final int totalAttempts;
  
  @JsonKey(name: 'best_score')
  final double bestScore;
  
  @JsonKey(name: 'last_attempt_date')
  final DateTime? lastAttemptDate;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  const QuizSummary({
    required this.quizId,
    required this.bookId,
    required this.bookTitle,
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.questionCount,
    required this.totalAttempts,
    required this.bestScore,
    this.lastAttemptDate,
    required this.createdAt,
  });
  
  factory QuizSummary.fromJson(Map<String, dynamic> json) =>
      _$QuizSummaryFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuizSummaryToJson(this);
  
  @override
  List<Object?> get props => [
        quizId,
        bookId,
        bookTitle,
        title,
        subject,
        difficulty,
        questionCount,
        totalAttempts,
        bestScore,
        lastAttemptDate,
        createdAt,
      ];
}

/// Result for individual question
@HiveType(typeId: 38)
@JsonSerializable()
class QuestionResult extends Equatable {
  @HiveField(0)
  final String questionId;
  
  @HiveField(1)
  final List<String> userAnswers; // Selected/provided answers
  
  @HiveField(2)
  final bool isCorrect;
  
  @HiveField(3)
  final int pointsEarned;
  
  @HiveField(4)
  final int maxPoints;
  
  @HiveField(5)
  final int timeSpent; // in seconds
  
  @HiveField(6)
  final int hintsUsed;
  
  @HiveField(7)
  final DateTime answeredAt;
  
  const QuestionResult({
    required this.questionId,
    required this.userAnswers,
    required this.isCorrect,
    required this.pointsEarned,
    required this.maxPoints,
    this.timeSpent = 0,
    this.hintsUsed = 0,
    required this.answeredAt,
  });
  
  factory QuestionResult.fromJson(Map<String, dynamic> json) => 
      _$QuestionResultFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuestionResultToJson(this);
  
  /// Calculate percentage score for this question
  double get percentage => maxPoints > 0 ? pointsEarned / maxPoints : 0.0;
  
  QuestionResult copyWith({
    String? questionId,
    List<String>? userAnswers,
    bool? isCorrect,
    int? pointsEarned,
    int? maxPoints,
    int? timeSpent,
    int? hintsUsed,
    DateTime? answeredAt,
  }) {
    return QuestionResult(
      questionId: questionId ?? this.questionId,
      userAnswers: userAnswers ?? this.userAnswers,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      maxPoints: maxPoints ?? this.maxPoints,
      timeSpent: timeSpent ?? this.timeSpent,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
  
  @override
  List<Object?> get props => [
        questionId,
        userAnswers,
        isCorrect,
        pointsEarned,
        maxPoints,
        timeSpent,
        hintsUsed,
        answeredAt,
      ];
}
