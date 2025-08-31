// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      avatarUrl: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      lastActiveAt: fields[5] as DateTime,
      preferences: fields[6] as UserPreferences,
      progress: fields[7] as UserProgress,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastActiveAt)
      ..writeByte(6)
      ..write(obj.preferences)
      ..writeByte(7)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 1;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      language: fields[0] as String,
      isDarkMode: fields[1] as bool,
      fontSize: fields[2] as double,
      aiTipsEnabled: fields[3] as bool,
      notificationsEnabled: fields[4] as bool,
      soundEnabled: fields[5] as bool,
      readingPreferences: fields[6] as ReadingPreferences,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.language)
      ..writeByte(1)
      ..write(obj.isDarkMode)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.aiTipsEnabled)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(5)
      ..write(obj.soundEnabled)
      ..writeByte(6)
      ..write(obj.readingPreferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingPreferencesAdapter extends TypeAdapter<ReadingPreferences> {
  @override
  final int typeId = 2;

  @override
  ReadingPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingPreferences(
      lineHeight: fields[0] as double,
      fontFamily: fields[1] as String,
      autoScroll: fields[2] as bool,
      autoScrollSpeed: fields[3] as int,
      highlightDifficultWords: fields[4] as bool,
      showDefinitionsOnTap: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingPreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lineHeight)
      ..writeByte(1)
      ..write(obj.fontFamily)
      ..writeByte(2)
      ..write(obj.autoScroll)
      ..writeByte(3)
      ..write(obj.autoScrollSpeed)
      ..writeByte(4)
      ..write(obj.highlightDifficultWords)
      ..writeByte(5)
      ..write(obj.showDefinitionsOnTap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 3;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      totalBooksRead: fields[0] as int,
      totalTimeSpent: fields[1] as int,
      currentStreak: fields[2] as int,
      longestStreak: fields[3] as int,
      totalQuizzesTaken: fields[4] as int,
      averageQuizScore: fields[5] as double,
      achievedBadges: (fields[6] as List).cast<String>(),
      subjectProgress: (fields[7] as Map).cast<String, SubjectProgress>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.totalBooksRead)
      ..writeByte(1)
      ..write(obj.totalTimeSpent)
      ..writeByte(2)
      ..write(obj.currentStreak)
      ..writeByte(3)
      ..write(obj.longestStreak)
      ..writeByte(4)
      ..write(obj.totalQuizzesTaken)
      ..writeByte(5)
      ..write(obj.averageQuizScore)
      ..writeByte(6)
      ..write(obj.achievedBadges)
      ..writeByte(7)
      ..write(obj.subjectProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectProgressAdapter extends TypeAdapter<SubjectProgress> {
  @override
  final int typeId = 4;

  @override
  SubjectProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectProgress(
      subjectId: fields[0] as String,
      subjectName: fields[1] as String,
      booksCompleted: fields[2] as int,
      timeSpent: fields[3] as int,
      averageScore: fields[4] as double,
      totalQuestions: fields[5] as int,
      correctAnswers: fields[6] as int,
      lastStudied: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.subjectId)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.booksCompleted)
      ..writeByte(3)
      ..write(obj.timeSpent)
      ..writeByte(4)
      ..write(obj.averageScore)
      ..writeByte(5)
      ..write(obj.totalQuestions)
      ..writeByte(6)
      ..write(obj.correctAnswers)
      ..writeByte(7)
      ..write(obj.lastStudied);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      preferences:
          UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      progress: UserProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'preferences': instance.preferences,
      'progress': instance.progress,
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      language: json['language'] as String? ?? 'en',
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      aiTipsEnabled: json['aiTipsEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      readingPreferences: ReadingPreferences.fromJson(
          json['readingPreferences'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'language': instance.language,
      'isDarkMode': instance.isDarkMode,
      'fontSize': instance.fontSize,
      'aiTipsEnabled': instance.aiTipsEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
      'soundEnabled': instance.soundEnabled,
      'readingPreferences': instance.readingPreferences,
    };

ReadingPreferences _$ReadingPreferencesFromJson(Map<String, dynamic> json) =>
    ReadingPreferences(
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      autoScroll: json['autoScroll'] as bool? ?? false,
      autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toInt() ?? 200,
      highlightDifficultWords: json['highlightDifficultWords'] as bool? ?? true,
      showDefinitionsOnTap: json['showDefinitionsOnTap'] as bool? ?? true,
    );

Map<String, dynamic> _$ReadingPreferencesToJson(ReadingPreferences instance) =>
    <String, dynamic>{
      'lineHeight': instance.lineHeight,
      'fontFamily': instance.fontFamily,
      'autoScroll': instance.autoScroll,
      'autoScrollSpeed': instance.autoScrollSpeed,
      'highlightDifficultWords': instance.highlightDifficultWords,
      'showDefinitionsOnTap': instance.showDefinitionsOnTap,
    };

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
      totalBooksRead: (json['totalBooksRead'] as num?)?.toInt() ?? 0,
      totalTimeSpent: (json['totalTimeSpent'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalQuizzesTaken: (json['totalQuizzesTaken'] as num?)?.toInt() ?? 0,
      averageQuizScore: (json['averageQuizScore'] as num?)?.toDouble() ?? 0.0,
      achievedBadges: (json['achievedBadges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      subjectProgress: (json['subjectProgress'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, SubjectProgress.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'totalBooksRead': instance.totalBooksRead,
      'totalTimeSpent': instance.totalTimeSpent,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'totalQuizzesTaken': instance.totalQuizzesTaken,
      'averageQuizScore': instance.averageQuizScore,
      'achievedBadges': instance.achievedBadges,
      'subjectProgress': instance.subjectProgress,
    };

SubjectProgress _$SubjectProgressFromJson(Map<String, dynamic> json) =>
    SubjectProgress(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      booksCompleted: (json['booksCompleted'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      lastStudied: DateTime.parse(json['lastStudied'] as String),
    );

Map<String, dynamic> _$SubjectProgressToJson(SubjectProgress instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'booksCompleted': instance.booksCompleted,
      'timeSpent': instance.timeSpent,
      'averageScore': instance.averageScore,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'lastStudied': instance.lastStudied.toIso8601String(),
    };
