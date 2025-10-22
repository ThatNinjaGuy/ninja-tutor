import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'book_model.g.dart';

/// Book model representing educational content
@HiveType(typeId: 10)
@JsonSerializable()
class BookModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String author;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  @JsonKey(name: 'cover_url')
  final String? coverUrl;
  
  @HiveField(5)
  final String subject;
  
  @HiveField(6)
  final String grade; // e.g., "Grade 8", "High School", "College"
  
  @HiveField(7)
  final BookType type;
  
  @HiveField(8)
  @JsonKey(name: 'file_path')
  final String? filePath; // Local file path for offline content
  
  @HiveField(9)
  @JsonKey(name: 'file_url')
  final String? fileUrl; // Remote URL for online content
  
  @HiveField(10)
  @JsonKey(name: 'total_pages')
  final int totalPages;
  
  @HiveField(11)
  @JsonKey(name: 'estimated_reading_time')
  final int? estimatedReadingTime; // in minutes
  
  @HiveField(12)
  @JsonKey(name: 'added_at')
  final DateTime addedAt;
  
  @HiveField(13)
  final DateTime? lastReadAt;
  
  @HiveField(14)
  final List<String> tags;
  
  @HiveField(15)
  final BookMetadata metadata;
  
  @HiveField(16)
  final ReadingProgress? progress;
  
  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    required this.subject,
    required this.grade,
    required this.type,
    this.filePath,
    this.fileUrl,
    required this.totalPages,
    this.estimatedReadingTime,
    required this.addedAt,
    this.lastReadAt,
    this.tags = const [],
    required this.metadata,
    this.progress,
  });
  
  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Handle backend API format with snake_case to camelCase conversion
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      subject: json['subject'] as String,
      grade: json['grade'] as String,
      type: _parseBookType(json['type'] as String?),
      filePath: json['file_path'] as String?,
      fileUrl: json['file_url'] as String?,
      totalPages: json['total_pages'] as int? ?? 0,
      estimatedReadingTime: json['estimated_reading_time'] as int?,
      addedAt: DateTime.parse(json['added_at'] as String),
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at'] as String) 
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: BookMetadata(
        format: json['type'] == 'pdf' ? 'PDF' : 'Unknown',
        language: 'en', // Default
        difficulty: DifficultyLevel.medium, // Default
      ),
      progress: json['progress'] != null 
          ? ReadingProgress(
              bookId: json['id'] as String,
              currentPage: json['progress']['current_page'] as int? ?? 0,
              totalPagesRead: json['progress']['pages_read_count'] as int? ?? 0,
              timeSpent: json['progress']['reading_time_minutes'] as int? ?? 0,
              lastReadAt: json['progress']['last_read_at'] != null 
                  ? DateTime.parse(json['progress']['last_read_at'] as String)
                  : DateTime.now(),
              startedAt: json['progress']['started_at'] != null 
                  ? DateTime.parse(json['progress']['started_at'] as String)
                  : DateTime.now(),
            )
          : null,
    );
  }

  static BookType _parseBookType(String? type) {
    switch (type?.toLowerCase()) {
      case 'textbook':
        return BookType.textbook;
      case 'reference':
        return BookType.reference;
      case 'novel':
        return BookType.novel;
      case 'workbook':
        return BookType.workbook;
      case 'magazine':
        return BookType.magazine;
      case 'research':
        return BookType.research;
      default:
        return BookType.other;
    }
  }
  
  Map<String, dynamic> toJson() => _$BookModelToJson(this);
  
  /// Check if book is available offline
  bool get isOfflineAvailable => filePath != null;
  
  /// Get reading progress percentage (based on pages with 60+ seconds reading time)
  double get progressPercentage {
    // The backend calculates pages_read_count based on pages with 60+ seconds reading time
    // totalPagesRead is populated from pages_read_count in the API response
    if (progress == null || totalPages == 0) return 0.0;
    
    // Use totalPagesRead which represents pages with 60+ seconds of reading time
    final percentage = progress!.totalPagesRead / totalPages;
    
    // Debug logging
    debugPrint('📊 Progress for "$title": ${progress!.totalPagesRead} pages read (60+ sec) / $totalPages total = ${(percentage * 100).toStringAsFixed(1)}%');
    
    return percentage;
  }
  
  /// Check if book is completed
  bool get isCompleted => progress?.isCompleted ?? false;
  
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? subject,
    String? grade,
    BookType? type,
    String? filePath,
    String? fileUrl,
    int? totalPages,
    int? estimatedReadingTime,
    DateTime? addedAt,
    DateTime? lastReadAt,
    List<String>? tags,
    BookMetadata? metadata,
    ReadingProgress? progress,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      totalPages: totalPages ?? this.totalPages,
      estimatedReadingTime: estimatedReadingTime ?? this.estimatedReadingTime,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      progress: progress ?? this.progress,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        title,
        author,
        description,
        coverUrl,
        subject,
        grade,
        type,
        filePath,
        fileUrl,
        totalPages,
        estimatedReadingTime,
        addedAt,
        lastReadAt,
        tags,
        metadata,
        progress,
      ];
}

/// Types of educational content
@HiveType(typeId: 11)
enum BookType {
  @HiveField(0)
  textbook,
  
  @HiveField(1)
  workbook,
  
  @HiveField(2)
  novel,
  
  @HiveField(3)
  reference,
  
  @HiveField(4)
  magazine,
  
  @HiveField(5)
  research,
  
  @HiveField(6)
  other,
}

/// Book metadata for additional information
@HiveType(typeId: 12)
@JsonSerializable()
class BookMetadata extends Equatable {
  @HiveField(0)
  final String? isbn;
  
  @HiveField(1)
  final String? publisher;
  
  @HiveField(2)
  final DateTime? publishedDate;
  
  @HiveField(3)
  final String? language;
  
  @HiveField(4)
  final String? edition;
  
  @HiveField(5)
  final List<String> keywords;
  
  @HiveField(6)
  final DifficultyLevel difficulty;
  
  @HiveField(7)
  final double? fileSize; // in MB
  
  @HiveField(8)
  final String? format; // PDF, EPUB, etc.
  
  const BookMetadata({
    this.isbn,
    this.publisher,
    this.publishedDate,
    this.language = 'en',
    this.edition,
    this.keywords = const [],
    this.difficulty = DifficultyLevel.medium,
    this.fileSize,
    this.format,
  });
  
  factory BookMetadata.fromJson(Map<String, dynamic> json) => 
      _$BookMetadataFromJson(json);
  
  Map<String, dynamic> toJson() => _$BookMetadataToJson(this);
  
  BookMetadata copyWith({
    String? isbn,
    String? publisher,
    DateTime? publishedDate,
    String? language,
    String? edition,
    List<String>? keywords,
    DifficultyLevel? difficulty,
    double? fileSize,
    String? format,
  }) {
    return BookMetadata(
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      language: language ?? this.language,
      edition: edition ?? this.edition,
      keywords: keywords ?? this.keywords,
      difficulty: difficulty ?? this.difficulty,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
    );
  }
  
  @override
  List<Object?> get props => [
        isbn,
        publisher,
        publishedDate,
        language,
        edition,
        keywords,
        difficulty,
        fileSize,
        format,
      ];
}

/// Difficulty levels for content
@HiveType(typeId: 13)
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

/// Reading progress tracking for a book
@HiveType(typeId: 14)
@JsonSerializable()
class ReadingProgress extends Equatable {
  @HiveField(0)
  final String bookId;
  
  @HiveField(1)
  final int currentPage;
  
  @HiveField(2)
  final int totalPagesRead;
  
  @HiveField(3)
  final int timeSpent; // in minutes
  
  @HiveField(4)
  final DateTime lastReadAt;
  
  @HiveField(5)
  final DateTime startedAt;
  
  @HiveField(6)
  final DateTime? completedAt;
  
  @HiveField(7)
  final List<ReadingSession> sessions;
  
  @HiveField(8)
  final Map<int, PageProgress> pageProgress; // Page number -> progress
  
  const ReadingProgress({
    required this.bookId,
    this.currentPage = 1,
    this.totalPagesRead = 0,
    this.timeSpent = 0,
    required this.lastReadAt,
    required this.startedAt,
    this.completedAt,
    this.sessions = const [],
    this.pageProgress = const {},
  });
  
  factory ReadingProgress.fromJson(Map<String, dynamic> json) => 
      _$ReadingProgressFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReadingProgressToJson(this);
  
  /// Check if reading is completed
  bool get isCompleted => completedAt != null;
  
  /// Calculate reading speed (pages per minute)
  double get readingSpeed {
    if (timeSpent == 0) return 0.0;
    return totalPagesRead / timeSpent;
  }
  
  ReadingProgress copyWith({
    String? bookId,
    int? currentPage,
    int? totalPagesRead,
    int? timeSpent,
    DateTime? lastReadAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ReadingSession>? sessions,
    Map<int, PageProgress>? pageProgress,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      timeSpent: timeSpent ?? this.timeSpent,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sessions: sessions ?? this.sessions,
      pageProgress: pageProgress ?? this.pageProgress,
    );
  }
  
  @override
  List<Object?> get props => [
        bookId,
        currentPage,
        totalPagesRead,
        timeSpent,
        lastReadAt,
        startedAt,
        completedAt,
        sessions,
        pageProgress,
      ];
}

/// Individual reading session data
@HiveType(typeId: 15)
@JsonSerializable()
class ReadingSession extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime startTime;
  
  @HiveField(2)
  final DateTime endTime;
  
  @HiveField(3)
  final int startPage;
  
  @HiveField(4)
  final int endPage;
  
  @HiveField(5)
  final int focusScore; // 1-100, based on interaction patterns
  
  const ReadingSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.startPage,
    required this.endPage,
    this.focusScore = 75,
  });
  
  factory ReadingSession.fromJson(Map<String, dynamic> json) => 
      _$ReadingSessionFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReadingSessionToJson(this);
  
  /// Calculate session duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;
  
  /// Calculate pages read in this session
  int get pagesRead => endPage - startPage + 1;
  
  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        startPage,
        endPage,
        focusScore,
      ];
}

/// Progress tracking for individual pages
@HiveType(typeId: 16)
@JsonSerializable()
class PageProgress extends Equatable {
  @HiveField(0)
  final int pageNumber;
  
  @HiveField(1)
  final int timeSpent; // in seconds
  
  @HiveField(2)
  final int visits; // number of times visited
  
  @HiveField(3)
  final DateTime firstVisit;
  
  @HiveField(4)
  final DateTime lastVisit;
  
  @HiveField(5)
  final bool isCompleted;
  
  @HiveField(6)
  final double comprehensionScore; // AI-estimated based on interactions
  
  const PageProgress({
    required this.pageNumber,
    this.timeSpent = 0,
    this.visits = 0,
    required this.firstVisit,
    required this.lastVisit,
    this.isCompleted = false,
    this.comprehensionScore = 0.0,
  });
  
  factory PageProgress.fromJson(Map<String, dynamic> json) => 
      _$PageProgressFromJson(json);
  
  Map<String, dynamic> toJson() => _$PageProgressToJson(this);
  
  PageProgress copyWith({
    int? pageNumber,
    int? timeSpent,
    int? visits,
    DateTime? firstVisit,
    DateTime? lastVisit,
    bool? isCompleted,
    double? comprehensionScore,
  }) {
    return PageProgress(
      pageNumber: pageNumber ?? this.pageNumber,
      timeSpent: timeSpent ?? this.timeSpent,
      visits: visits ?? this.visits,
      firstVisit: firstVisit ?? this.firstVisit,
      lastVisit: lastVisit ?? this.lastVisit,
      isCompleted: isCompleted ?? this.isCompleted,
      comprehensionScore: comprehensionScore ?? this.comprehensionScore,
    );
  }
  
  @override
  List<Object?> get props => [
        pageNumber,
        timeSpent,
        visits,
        firstVisit,
        lastVisit,
        isCompleted,
        comprehensionScore,
      ];
}
