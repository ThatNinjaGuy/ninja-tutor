import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User model representing a student's profile and preferences
@HiveType(typeId: 0)
@JsonSerializable()
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? avatarUrl;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime lastActiveAt;
  
  @HiveField(6)
  final UserPreferences preferences;
  
  @HiveField(7)
  final UserProgress progress;
  
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.lastActiveAt,
    required this.preferences,
    required this.progress,
  });
  
  /// Create user from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  /// Convert user to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    UserPreferences? preferences,
    UserProgress? progress,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      progress: progress ?? this.progress,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        createdAt,
        lastActiveAt,
        preferences,
        progress,
      ];
}

/// User preferences for app customization
@HiveType(typeId: 1)
@JsonSerializable()
class UserPreferences extends Equatable {
  @HiveField(0)
  final String language;
  
  @HiveField(1)
  final bool isDarkMode;
  
  @HiveField(2)
  final double fontSize;
  
  @HiveField(3)
  final bool aiTipsEnabled;
  
  @HiveField(4)
  final bool notificationsEnabled;
  
  @HiveField(5)
  final bool soundEnabled;
  
  @HiveField(6)
  final ReadingPreferences readingPreferences;
  
  @HiveField(7)
  final String? classGrade;
  
  const UserPreferences({
    this.language = 'en',
    this.isDarkMode = false,
    this.fontSize = 16.0,
    this.aiTipsEnabled = true,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.classGrade,
    required this.readingPreferences,
  });
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    // Handle snake_case to camelCase conversion for classGrade
    if (json.containsKey('class_grade') && !json.containsKey('classGrade')) {
      json['classGrade'] = json['class_grade'];
    }
    return _$UserPreferencesFromJson(json);
  }
  
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
  
  UserPreferences copyWith({
    String? language,
    bool? isDarkMode,
    double? fontSize,
    bool? aiTipsEnabled,
    bool? notificationsEnabled,
    bool? soundEnabled,
    ReadingPreferences? readingPreferences,
    String? classGrade,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      aiTipsEnabled: aiTipsEnabled ?? this.aiTipsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      readingPreferences: readingPreferences ?? this.readingPreferences,
      classGrade: classGrade ?? this.classGrade,
    );
  }
  
  @override
  List<Object?> get props => [
        language,
        isDarkMode,
        fontSize,
        aiTipsEnabled,
        notificationsEnabled,
        soundEnabled,
        readingPreferences,
        classGrade,
      ];
}

/// Reading-specific user preferences
@HiveType(typeId: 2)
@JsonSerializable()
class ReadingPreferences extends Equatable {
  @HiveField(0)
  final double lineHeight;
  
  @HiveField(1)
  final String fontFamily;
  
  @HiveField(2)
  final bool autoScroll;
  
  @HiveField(3)
  final int autoScrollSpeed; // words per minute
  
  @HiveField(4)
  final bool highlightDifficultWords;
  
  @HiveField(5)
  final bool showDefinitionsOnTap;
  
  const ReadingPreferences({
    this.lineHeight = 1.5,
    this.fontFamily = 'Inter',
    this.autoScroll = false,
    this.autoScrollSpeed = 200,
    this.highlightDifficultWords = true,
    this.showDefinitionsOnTap = true,
  });
  
  factory ReadingPreferences.fromJson(Map<String, dynamic> json) => 
      _$ReadingPreferencesFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReadingPreferencesToJson(this);
  
  ReadingPreferences copyWith({
    double? lineHeight,
    String? fontFamily,
    bool? autoScroll,
    int? autoScrollSpeed,
    bool? highlightDifficultWords,
    bool? showDefinitionsOnTap,
  }) {
    return ReadingPreferences(
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      autoScroll: autoScroll ?? this.autoScroll,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      highlightDifficultWords: highlightDifficultWords ?? this.highlightDifficultWords,
      showDefinitionsOnTap: showDefinitionsOnTap ?? this.showDefinitionsOnTap,
    );
  }
  
  @override
  List<Object?> get props => [
        lineHeight,
        fontFamily,
        autoScroll,
        autoScrollSpeed,
        highlightDifficultWords,
        showDefinitionsOnTap,
      ];
}

/// User progress tracking
@HiveType(typeId: 3)
@JsonSerializable()
class UserProgress extends Equatable {
  @HiveField(0)
  final int totalBooksRead;
  
  @HiveField(1)
  final int totalTimeSpent; // in minutes
  
  @HiveField(2)
  final int currentStreak; // consecutive days
  
  @HiveField(3)
  final int longestStreak;
  
  @HiveField(4)
  final int totalQuizzesTaken;
  
  @HiveField(5)
  final double averageQuizScore;
  
  @HiveField(6)
  final List<String> achievedBadges;
  
  @HiveField(7)
  final Map<String, SubjectProgress> subjectProgress;
  
  const UserProgress({
    this.totalBooksRead = 0,
    this.totalTimeSpent = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalQuizzesTaken = 0,
    this.averageQuizScore = 0.0,
    this.achievedBadges = const [],
    this.subjectProgress = const {},
  });
  
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // Ensure empty subjectProgress if not present
    if (!json.containsKey('subjectProgress') && !json.containsKey('subjects_progress')) {
      json['subjectProgress'] = {};
    } else if (json.containsKey('subjects_progress')) {
      json['subjectProgress'] = json['subjects_progress'];
    }
    return _$UserProgressFromJson(json);
  }
  
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
  
  UserProgress copyWith({
    int? totalBooksRead,
    int? totalTimeSpent,
    int? currentStreak,
    int? longestStreak,
    int? totalQuizzesTaken,
    double? averageQuizScore,
    List<String>? achievedBadges,
    Map<String, SubjectProgress>? subjectProgress,
  }) {
    return UserProgress(
      totalBooksRead: totalBooksRead ?? this.totalBooksRead,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
      achievedBadges: achievedBadges ?? this.achievedBadges,
      subjectProgress: subjectProgress ?? this.subjectProgress,
    );
  }
  
  @override
  List<Object?> get props => [
        totalBooksRead,
        totalTimeSpent,
        currentStreak,
        longestStreak,
        totalQuizzesTaken,
        averageQuizScore,
        achievedBadges,
        subjectProgress,
      ];
}

/// Progress tracking for individual subjects
@HiveType(typeId: 4)
@JsonSerializable()
class SubjectProgress extends Equatable {
  @HiveField(0)
  final String subjectId;
  
  @HiveField(1)
  final String subjectName;
  
  @HiveField(2)
  final int booksCompleted;
  
  @HiveField(3)
  final int timeSpent; // in minutes
  
  @HiveField(4)
  final double averageScore;
  
  @HiveField(5)
  final int totalQuestions;
  
  @HiveField(6)
  final int correctAnswers;
  
  @HiveField(7)
  final DateTime lastStudied;
  
  const SubjectProgress({
    required this.subjectId,
    required this.subjectName,
    this.booksCompleted = 0,
    this.timeSpent = 0,
    this.averageScore = 0.0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    required this.lastStudied,
  });
  
  factory SubjectProgress.fromJson(Map<String, dynamic> json) => 
      _$SubjectProgressFromJson(json);
  
  Map<String, dynamic> toJson() => _$SubjectProgressToJson(this);
  
  /// Calculate accuracy percentage
  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
  
  SubjectProgress copyWith({
    String? subjectId,
    String? subjectName,
    int? booksCompleted,
    int? timeSpent,
    double? averageScore,
    int? totalQuestions,
    int? correctAnswers,
    DateTime? lastStudied,
  }) {
    return SubjectProgress(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      booksCompleted: booksCompleted ?? this.booksCompleted,
      timeSpent: timeSpent ?? this.timeSpent,
      averageScore: averageScore ?? this.averageScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }
  
  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        booksCompleted,
        timeSpent,
        averageScore,
        totalQuestions,
        correctAnswers,
        lastStudied,
      ];
}
