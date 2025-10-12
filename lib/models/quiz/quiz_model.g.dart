// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizModelAdapter extends TypeAdapter<QuizModel> {
  @override
  final int typeId = 30;

  @override
  QuizModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      bookId: fields[3] as String,
      subject: fields[4] as String,
      pageRange: (fields[5] as List).cast<int>(),
      questions: (fields[6] as List).cast<QuestionModel>(),
      settings: fields[7] as QuizSettings,
      createdAt: fields[8] as DateTime,
      type: fields[9] as QuizType,
      difficulty: fields[10] as DifficultyLevel,
      tags: (fields[11] as List).cast<String>(),
      isAdaptive: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QuizModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.bookId)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.pageRange)
      ..writeByte(6)
      ..write(obj.questions)
      ..writeByte(7)
      ..write(obj.settings)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.difficulty)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.isAdaptive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizSettingsAdapter extends TypeAdapter<QuizSettings> {
  @override
  final int typeId = 33;

  @override
  QuizSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizSettings(
      timeLimit: fields[0] as int?,
      shuffleQuestions: fields[1] as bool,
      shuffleAnswers: fields[2] as bool,
      showFeedback: fields[3] as bool,
      allowReview: fields[4] as bool,
      showCorrectAnswers: fields[5] as bool,
      maxAttempts: fields[6] as int,
      passingScore: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, QuizSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.timeLimit)
      ..writeByte(1)
      ..write(obj.shuffleQuestions)
      ..writeByte(2)
      ..write(obj.shuffleAnswers)
      ..writeByte(3)
      ..write(obj.showFeedback)
      ..writeByte(4)
      ..write(obj.allowReview)
      ..writeByte(5)
      ..write(obj.showCorrectAnswers)
      ..writeByte(6)
      ..write(obj.maxAttempts)
      ..writeByte(7)
      ..write(obj.passingScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionModelAdapter extends TypeAdapter<QuestionModel> {
  @override
  final int typeId = 34;

  @override
  QuestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionModel(
      id: fields[0] as String,
      question: fields[1] as String,
      type: fields[2] as QuestionType,
      options: (fields[3] as List).cast<AnswerOption>(),
      correctAnswer: fields[4] as String?,
      correctAnswers: (fields[5] as List).cast<String>(),
      explanation: fields[6] as String?,
      points: fields[7] as int,
      difficulty: fields[8] as DifficultyLevel,
      hints: (fields[9] as List).cast<String>(),
      imageUrl: fields[10] as String?,
      audioUrl: fields[11] as String?,
      tags: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, QuestionModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.options)
      ..writeByte(4)
      ..write(obj.correctAnswer)
      ..writeByte(5)
      ..write(obj.correctAnswers)
      ..writeByte(6)
      ..write(obj.explanation)
      ..writeByte(7)
      ..write(obj.points)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(9)
      ..write(obj.hints)
      ..writeByte(10)
      ..write(obj.imageUrl)
      ..writeByte(11)
      ..write(obj.audioUrl)
      ..writeByte(12)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnswerOptionAdapter extends TypeAdapter<AnswerOption> {
  @override
  final int typeId = 36;

  @override
  AnswerOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnswerOption(
      id: fields[0] as String,
      text: fields[1] as String,
      isCorrect: fields[2] as bool,
      explanation: fields[3] as String?,
      imageUrl: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnswerOption obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.isCorrect)
      ..writeByte(3)
      ..write(obj.explanation)
      ..writeByte(4)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizResultAdapter extends TypeAdapter<QuizResult> {
  @override
  final int typeId = 37;

  @override
  QuizResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizResult(
      id: fields[0] as String,
      quizId: fields[1] as String,
      userId: fields[2] as String,
      questionResults: (fields[3] as List).cast<QuestionResult>(),
      totalScore: fields[4] as int,
      maxScore: fields[5] as int,
      startedAt: fields[6] as DateTime?,
      completedAt: fields[7] as DateTime,
      isPassed: fields[8] as bool,
      attemptNumber: fields[9] as int,
      analytics: (fields[10] as Map).cast<String, dynamic>(),
      percentageValue: fields[11] as double?,
      correctAnswersCount: fields[12] as int?,
      incorrectAnswersCount: fields[13] as int?,
      timeTakenMinutes: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, QuizResult obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quizId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.questionResults)
      ..writeByte(4)
      ..write(obj.totalScore)
      ..writeByte(5)
      ..write(obj.maxScore)
      ..writeByte(6)
      ..write(obj.startedAt)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.isPassed)
      ..writeByte(9)
      ..write(obj.attemptNumber)
      ..writeByte(10)
      ..write(obj.analytics)
      ..writeByte(11)
      ..write(obj.percentageValue)
      ..writeByte(12)
      ..write(obj.correctAnswersCount)
      ..writeByte(13)
      ..write(obj.incorrectAnswersCount)
      ..writeByte(14)
      ..write(obj.timeTakenMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionResultAdapter extends TypeAdapter<QuestionResult> {
  @override
  final int typeId = 38;

  @override
  QuestionResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionResult(
      questionId: fields[0] as String,
      userAnswers: (fields[1] as List).cast<String>(),
      isCorrect: fields[2] as bool,
      pointsEarned: fields[3] as int,
      maxPoints: fields[4] as int,
      timeSpent: fields[5] as int,
      hintsUsed: fields[6] as int,
      answeredAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.userAnswers)
      ..writeByte(2)
      ..write(obj.isCorrect)
      ..writeByte(3)
      ..write(obj.pointsEarned)
      ..writeByte(4)
      ..write(obj.maxPoints)
      ..writeByte(5)
      ..write(obj.timeSpent)
      ..writeByte(6)
      ..write(obj.hintsUsed)
      ..writeByte(7)
      ..write(obj.answeredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizTypeAdapter extends TypeAdapter<QuizType> {
  @override
  final int typeId = 31;

  @override
  QuizType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuizType.practice;
      case 1:
        return QuizType.assessment;
      case 2:
        return QuizType.review;
      case 3:
        return QuizType.adaptive;
      case 4:
        return QuizType.timed;
      case 5:
        return QuizType.final_;
      default:
        return QuizType.practice;
    }
  }

  @override
  void write(BinaryWriter writer, QuizType obj) {
    switch (obj) {
      case QuizType.practice:
        writer.writeByte(0);
        break;
      case QuizType.assessment:
        writer.writeByte(1);
        break;
      case QuizType.review:
        writer.writeByte(2);
        break;
      case QuizType.adaptive:
        writer.writeByte(3);
        break;
      case QuizType.timed:
        writer.writeByte(4);
        break;
      case QuizType.final_:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 32;

  @override
  DifficultyLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DifficultyLevel.beginner;
      case 1:
        return DifficultyLevel.easy;
      case 2:
        return DifficultyLevel.medium;
      case 3:
        return DifficultyLevel.hard;
      case 4:
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, DifficultyLevel obj) {
    switch (obj) {
      case DifficultyLevel.beginner:
        writer.writeByte(0);
        break;
      case DifficultyLevel.easy:
        writer.writeByte(1);
        break;
      case DifficultyLevel.medium:
        writer.writeByte(2);
        break;
      case DifficultyLevel.hard:
        writer.writeByte(3);
        break;
      case DifficultyLevel.expert:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionTypeAdapter extends TypeAdapter<QuestionType> {
  @override
  final int typeId = 35;

  @override
  QuestionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionType.multipleChoice;
      case 1:
        return QuestionType.multipleSelect;
      case 2:
        return QuestionType.trueFalse;
      case 3:
        return QuestionType.shortAnswer;
      case 4:
        return QuestionType.essay;
      case 5:
        return QuestionType.fillInTheBlank;
      case 6:
        return QuestionType.matching;
      case 7:
        return QuestionType.ordering;
      case 8:
        return QuestionType.audio;
      case 9:
        return QuestionType.video;
      default:
        return QuestionType.multipleChoice;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionType obj) {
    switch (obj) {
      case QuestionType.multipleChoice:
        writer.writeByte(0);
        break;
      case QuestionType.multipleSelect:
        writer.writeByte(1);
        break;
      case QuestionType.trueFalse:
        writer.writeByte(2);
        break;
      case QuestionType.shortAnswer:
        writer.writeByte(3);
        break;
      case QuestionType.essay:
        writer.writeByte(4);
        break;
      case QuestionType.fillInTheBlank:
        writer.writeByte(5);
        break;
      case QuestionType.matching:
        writer.writeByte(6);
        break;
      case QuestionType.ordering:
        writer.writeByte(7);
        break;
      case QuestionType.audio:
        writer.writeByte(8);
        break;
      case QuestionType.video:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizModel _$QuizModelFromJson(Map<String, dynamic> json) => QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      bookId: json['book_id'] as String,
      subject: json['subject'] as String,
      pageRange: (json['page_range'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: QuizSettings.fromJson(json['settings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      type: $enumDecode(_$QuizTypeEnumMap, json['type']),
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isAdaptive: json['isAdaptive'] as bool? ?? false,
    );

Map<String, dynamic> _$QuizModelToJson(QuizModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'book_id': instance.bookId,
      'subject': instance.subject,
      'page_range': instance.pageRange,
      'questions': instance.questions,
      'settings': instance.settings,
      'created_at': instance.createdAt.toIso8601String(),
      'type': _$QuizTypeEnumMap[instance.type]!,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'tags': instance.tags,
      'isAdaptive': instance.isAdaptive,
    };

const _$QuizTypeEnumMap = {
  QuizType.practice: 'practice',
  QuizType.assessment: 'assessment',
  QuizType.review: 'review',
  QuizType.adaptive: 'adaptive',
  QuizType.timed: 'timed',
  QuizType.final_: 'final_',
};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.easy: 'easy',
  DifficultyLevel.medium: 'medium',
  DifficultyLevel.hard: 'hard',
  DifficultyLevel.expert: 'expert',
};

QuizSettings _$QuizSettingsFromJson(Map<String, dynamic> json) => QuizSettings(
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      shuffleAnswers: json['shuffle_options'] as bool? ?? false,
      showFeedback: json['showFeedback'] as bool? ?? true,
      allowReview: json['allow_retakes'] as bool? ?? true,
      showCorrectAnswers: json['show_results_immediately'] as bool? ?? true,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 3,
      passingScore: (json['passingScore'] as num?)?.toDouble() ?? 0.7,
    );

Map<String, dynamic> _$QuizSettingsToJson(QuizSettings instance) =>
    <String, dynamic>{
      'timeLimit': instance.timeLimit,
      'shuffle_questions': instance.shuffleQuestions,
      'shuffle_options': instance.shuffleAnswers,
      'showFeedback': instance.showFeedback,
      'allow_retakes': instance.allowReview,
      'show_results_immediately': instance.showCorrectAnswers,
      'maxAttempts': instance.maxAttempts,
      'passingScore': instance.passingScore,
    };

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    QuestionModel(
      id: json['id'] as String,
      question: json['question_text'] as String,
      type: $enumDecode(_$QuestionTypeEnumMap, json['type']),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => AnswerOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      correctAnswer: json['correct_answer'] as String?,
      correctAnswers: (json['correct_answers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      explanation: json['explanation'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 1,
      difficulty:
          $enumDecodeNullable(_$DifficultyLevelEnumMap, json['difficulty']) ??
              DifficultyLevel.medium,
      hints:
          (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_text': instance.question,
      'type': _$QuestionTypeEnumMap[instance.type]!,
      'options': instance.options,
      'correct_answer': instance.correctAnswer,
      'correct_answers': instance.correctAnswers,
      'explanation': instance.explanation,
      'points': instance.points,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'hints': instance.hints,
      'image_url': instance.imageUrl,
      'audio_url': instance.audioUrl,
      'tags': instance.tags,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.multipleChoice: 'multipleChoice',
  QuestionType.multipleSelect: 'multipleSelect',
  QuestionType.trueFalse: 'trueFalse',
  QuestionType.shortAnswer: 'shortAnswer',
  QuestionType.essay: 'essay',
  QuestionType.fillInTheBlank: 'fillInTheBlank',
  QuestionType.matching: 'matching',
  QuestionType.ordering: 'ordering',
  QuestionType.audio: 'audio',
  QuestionType.video: 'video',
};

AnswerOption _$AnswerOptionFromJson(Map<String, dynamic> json) => AnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['is_correct'] as bool,
      explanation: json['explanation'] as String?,
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$AnswerOptionToJson(AnswerOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'is_correct': instance.isCorrect,
      'explanation': instance.explanation,
      'image_url': instance.imageUrl,
    };

QuizResult _$QuizResultFromJson(Map<String, dynamic> json) => QuizResult(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      userId: json['user_id'] as String,
      questionResults: (json['question_results'] as List<dynamic>?)
              ?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalScore: (json['total_score'] as num).toInt(),
      maxScore: (json['max_score'] as num).toInt(),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
      isPassed: json['is_passed'] as bool,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      analytics: json['analytics'] as Map<String, dynamic>? ?? const {},
      percentageValue: (json['percentage'] as num?)?.toDouble(),
      correctAnswersCount: (json['correct_answers'] as num?)?.toInt(),
      incorrectAnswersCount: (json['incorrect_answers'] as num?)?.toInt(),
      timeTakenMinutes: (json['time_taken'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuizResultToJson(QuizResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_id': instance.quizId,
      'user_id': instance.userId,
      'question_results': instance.questionResults,
      'total_score': instance.totalScore,
      'max_score': instance.maxScore,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt.toIso8601String(),
      'is_passed': instance.isPassed,
      'attempt_number': instance.attemptNumber,
      'analytics': instance.analytics,
      'percentage': instance.percentageValue,
      'correct_answers': instance.correctAnswersCount,
      'incorrect_answers': instance.incorrectAnswersCount,
      'time_taken': instance.timeTakenMinutes,
    };

QuizSummary _$QuizSummaryFromJson(Map<String, dynamic> json) => QuizSummary(
      quizId: json['quiz_id'] as String,
      bookId: json['book_id'] as String,
      bookTitle: json['book_title'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      difficulty: json['difficulty'] as String,
      questionCount: (json['question_count'] as num).toInt(),
      totalAttempts: (json['total_attempts'] as num).toInt(),
      bestScore: (json['best_score'] as num).toDouble(),
      lastAttemptDate: json['last_attempt_date'] == null
          ? null
          : DateTime.parse(json['last_attempt_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$QuizSummaryToJson(QuizSummary instance) =>
    <String, dynamic>{
      'quiz_id': instance.quizId,
      'book_id': instance.bookId,
      'book_title': instance.bookTitle,
      'title': instance.title,
      'subject': instance.subject,
      'difficulty': instance.difficulty,
      'question_count': instance.questionCount,
      'total_attempts': instance.totalAttempts,
      'best_score': instance.bestScore,
      'last_attempt_date': instance.lastAttemptDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

QuestionResult _$QuestionResultFromJson(Map<String, dynamic> json) =>
    QuestionResult(
      questionId: json['questionId'] as String,
      userAnswers: (json['userAnswers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isCorrect: json['isCorrect'] as bool,
      pointsEarned: (json['pointsEarned'] as num).toInt(),
      maxPoints: (json['maxPoints'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );

Map<String, dynamic> _$QuestionResultToJson(QuestionResult instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'userAnswers': instance.userAnswers,
      'isCorrect': instance.isCorrect,
      'pointsEarned': instance.pointsEarned,
      'maxPoints': instance.maxPoints,
      'timeSpent': instance.timeSpent,
      'hintsUsed': instance.hintsUsed,
      'answeredAt': instance.answeredAt.toIso8601String(),
    };
