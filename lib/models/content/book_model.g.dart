// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookModelAdapter extends TypeAdapter<BookModel> {
  @override
  final int typeId = 10;

  @override
  BookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookModel(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String?,
      coverUrl: fields[4] as String?,
      subject: fields[5] as String,
      grade: fields[6] as String,
      type: fields[7] as BookType,
      filePath: fields[8] as String?,
      fileUrl: fields[9] as String?,
      totalPages: fields[10] as int,
      estimatedReadingTime: fields[11] as int?,
      addedAt: fields[12] as DateTime,
      lastReadAt: fields[13] as DateTime?,
      tags: (fields[14] as List).cast<String>(),
      metadata: fields[15] as BookMetadata,
      progress: fields[16] as ReadingProgress?,
    );
  }

  @override
  void write(BinaryWriter writer, BookModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.coverUrl)
      ..writeByte(5)
      ..write(obj.subject)
      ..writeByte(6)
      ..write(obj.grade)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.fileUrl)
      ..writeByte(10)
      ..write(obj.totalPages)
      ..writeByte(11)
      ..write(obj.estimatedReadingTime)
      ..writeByte(12)
      ..write(obj.addedAt)
      ..writeByte(13)
      ..write(obj.lastReadAt)
      ..writeByte(14)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.metadata)
      ..writeByte(16)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookMetadataAdapter extends TypeAdapter<BookMetadata> {
  @override
  final int typeId = 12;

  @override
  BookMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookMetadata(
      isbn: fields[0] as String?,
      publisher: fields[1] as String?,
      publishedDate: fields[2] as DateTime?,
      language: fields[3] as String?,
      edition: fields[4] as String?,
      keywords: (fields[5] as List).cast<String>(),
      difficulty: fields[6] as DifficultyLevel,
      fileSize: fields[7] as double?,
      format: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BookMetadata obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.isbn)
      ..writeByte(1)
      ..write(obj.publisher)
      ..writeByte(2)
      ..write(obj.publishedDate)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.edition)
      ..writeByte(5)
      ..write(obj.keywords)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.fileSize)
      ..writeByte(8)
      ..write(obj.format);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingProgressAdapter extends TypeAdapter<ReadingProgress> {
  @override
  final int typeId = 14;

  @override
  ReadingProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingProgress(
      bookId: fields[0] as String,
      currentPage: fields[1] as int,
      totalPagesRead: fields[2] as int,
      timeSpent: fields[3] as int,
      lastReadAt: fields[4] as DateTime,
      startedAt: fields[5] as DateTime,
      completedAt: fields[6] as DateTime?,
      sessions: (fields[7] as List).cast<ReadingSession>(),
      pageProgress: (fields[8] as Map).cast<int, PageProgress>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReadingProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.bookId)
      ..writeByte(1)
      ..write(obj.currentPage)
      ..writeByte(2)
      ..write(obj.totalPagesRead)
      ..writeByte(3)
      ..write(obj.timeSpent)
      ..writeByte(4)
      ..write(obj.lastReadAt)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.sessions)
      ..writeByte(8)
      ..write(obj.pageProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingSessionAdapter extends TypeAdapter<ReadingSession> {
  @override
  final int typeId = 15;

  @override
  ReadingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      startPage: fields[3] as int,
      endPage: fields[4] as int,
      focusScore: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.startPage)
      ..writeByte(4)
      ..write(obj.endPage)
      ..writeByte(5)
      ..write(obj.focusScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageProgressAdapter extends TypeAdapter<PageProgress> {
  @override
  final int typeId = 16;

  @override
  PageProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageProgress(
      pageNumber: fields[0] as int,
      timeSpent: fields[1] as int,
      visits: fields[2] as int,
      firstVisit: fields[3] as DateTime,
      lastVisit: fields[4] as DateTime,
      isCompleted: fields[5] as bool,
      comprehensionScore: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PageProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.pageNumber)
      ..writeByte(1)
      ..write(obj.timeSpent)
      ..writeByte(2)
      ..write(obj.visits)
      ..writeByte(3)
      ..write(obj.firstVisit)
      ..writeByte(4)
      ..write(obj.lastVisit)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.comprehensionScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookTypeAdapter extends TypeAdapter<BookType> {
  @override
  final int typeId = 11;

  @override
  BookType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookType.textbook;
      case 1:
        return BookType.workbook;
      case 2:
        return BookType.novel;
      case 3:
        return BookType.reference;
      case 4:
        return BookType.magazine;
      case 5:
        return BookType.research;
      case 6:
        return BookType.other;
      default:
        return BookType.textbook;
    }
  }

  @override
  void write(BinaryWriter writer, BookType obj) {
    switch (obj) {
      case BookType.textbook:
        writer.writeByte(0);
        break;
      case BookType.workbook:
        writer.writeByte(1);
        break;
      case BookType.novel:
        writer.writeByte(2);
        break;
      case BookType.reference:
        writer.writeByte(3);
        break;
      case BookType.magazine:
        writer.writeByte(4);
        break;
      case BookType.research:
        writer.writeByte(5);
        break;
      case BookType.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 13;

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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookModel _$BookModelFromJson(Map<String, dynamic> json) => BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      subject: json['subject'] as String,
      grade: json['grade'] as String,
      type: $enumDecode(_$BookTypeEnumMap, json['type']),
      filePath: json['filePath'] as String?,
      fileUrl: json['fileUrl'] as String?,
      totalPages: (json['totalPages'] as num).toInt(),
      estimatedReadingTime: (json['estimatedReadingTime'] as num?)?.toInt(),
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      metadata: BookMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      progress: json['progress'] == null
          ? null
          : ReadingProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BookModelToJson(BookModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'subject': instance.subject,
      'grade': instance.grade,
      'type': _$BookTypeEnumMap[instance.type]!,
      'filePath': instance.filePath,
      'fileUrl': instance.fileUrl,
      'totalPages': instance.totalPages,
      'estimatedReadingTime': instance.estimatedReadingTime,
      'addedAt': instance.addedAt.toIso8601String(),
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'tags': instance.tags,
      'metadata': instance.metadata,
      'progress': instance.progress,
    };

const _$BookTypeEnumMap = {
  BookType.textbook: 'textbook',
  BookType.workbook: 'workbook',
  BookType.novel: 'novel',
  BookType.reference: 'reference',
  BookType.magazine: 'magazine',
  BookType.research: 'research',
  BookType.other: 'other',
};

BookMetadata _$BookMetadataFromJson(Map<String, dynamic> json) => BookMetadata(
      isbn: json['isbn'] as String?,
      publisher: json['publisher'] as String?,
      publishedDate: json['publishedDate'] == null
          ? null
          : DateTime.parse(json['publishedDate'] as String),
      language: json['language'] as String? ?? 'en',
      edition: json['edition'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      difficulty:
          $enumDecodeNullable(_$DifficultyLevelEnumMap, json['difficulty']) ??
              DifficultyLevel.medium,
      fileSize: (json['fileSize'] as num?)?.toDouble(),
      format: json['format'] as String?,
    );

Map<String, dynamic> _$BookMetadataToJson(BookMetadata instance) =>
    <String, dynamic>{
      'isbn': instance.isbn,
      'publisher': instance.publisher,
      'publishedDate': instance.publishedDate?.toIso8601String(),
      'language': instance.language,
      'edition': instance.edition,
      'keywords': instance.keywords,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'fileSize': instance.fileSize,
      'format': instance.format,
    };

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.easy: 'easy',
  DifficultyLevel.medium: 'medium',
  DifficultyLevel.hard: 'hard',
  DifficultyLevel.expert: 'expert',
};

ReadingProgress _$ReadingProgressFromJson(Map<String, dynamic> json) =>
    ReadingProgress(
      bookId: json['bookId'] as String,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPagesRead: (json['totalPagesRead'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => ReadingSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pageProgress: (json['pageProgress'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                int.parse(k), PageProgress.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$ReadingProgressToJson(ReadingProgress instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'currentPage': instance.currentPage,
      'totalPagesRead': instance.totalPagesRead,
      'timeSpent': instance.timeSpent,
      'lastReadAt': instance.lastReadAt.toIso8601String(),
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'sessions': instance.sessions,
      'pageProgress':
          instance.pageProgress.map((k, e) => MapEntry(k.toString(), e)),
    };

ReadingSession _$ReadingSessionFromJson(Map<String, dynamic> json) =>
    ReadingSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      startPage: (json['startPage'] as num).toInt(),
      endPage: (json['endPage'] as num).toInt(),
      focusScore: (json['focusScore'] as num?)?.toInt() ?? 75,
    );

Map<String, dynamic> _$ReadingSessionToJson(ReadingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'startPage': instance.startPage,
      'endPage': instance.endPage,
      'focusScore': instance.focusScore,
    };

PageProgress _$PageProgressFromJson(Map<String, dynamic> json) => PageProgress(
      pageNumber: (json['pageNumber'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      visits: (json['visits'] as num?)?.toInt() ?? 0,
      firstVisit: DateTime.parse(json['firstVisit'] as String),
      lastVisit: DateTime.parse(json['lastVisit'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      comprehensionScore:
          (json['comprehensionScore'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$PageProgressToJson(PageProgress instance) =>
    <String, dynamic>{
      'pageNumber': instance.pageNumber,
      'timeSpent': instance.timeSpent,
      'visits': instance.visits,
      'firstVisit': instance.firstVisit.toIso8601String(),
      'lastVisit': instance.lastVisit.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'comprehensionScore': instance.comprehensionScore,
    };
