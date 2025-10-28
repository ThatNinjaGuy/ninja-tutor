import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'note_model.g.dart';

/// Note model for user-created notes and highlights
@HiveType(typeId: 20)
@JsonSerializable()
class NoteModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String bookId;
  
  @HiveField(2)
  final int pageNumber;
  
  @HiveField(3)
  final NoteType type;
  
  @HiveField(4)
  final String content;
  
  @HiveField(5)
  final String? title;
  
  @HiveField(6)
  final List<String> tags;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime updatedAt;
  
  @HiveField(9)
  final NotePosition position;
  
  @HiveField(10)
  final NoteStyle style;
  
  @HiveField(11)
  final bool isFavorite;
  
  @HiveField(12)
  final String? linkedText; // Original text for highlights
  
  @HiveField(13)
  final AiInsights? aiInsights; // AI-generated insights
  
  @HiveField(14)
  @JsonKey(name: 'selected_text')
  final String? selectedText; // Text selected from PDF that the note was created for
  
  const NoteModel({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.type,
    required this.content,
    this.title,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.position,
    required this.style,
    this.isFavorite = false,
    this.linkedText,
    this.aiInsights,
    this.selectedText,
  });
  
  factory NoteModel.fromJson(Map<String, dynamic> json) => 
      _$NoteModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$NoteModelToJson(this);
  
  /// Check if note is a highlight
  bool get isHighlight => type == NoteType.highlight;
  
  /// Check if note is a text note
  bool get isTextNote => type == NoteType.text;
  
  /// Check if note is a drawing/sketch
  bool get isDrawing => type == NoteType.drawing;
  
  /// Get display title (use title or truncated content)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }
  
  NoteModel copyWith({
    String? id,
    String? bookId,
    int? pageNumber,
    NoteType? type,
    String? content,
    String? title,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotePosition? position,
    NoteStyle? style,
    bool? isFavorite,
    String? linkedText,
    AiInsights? aiInsights,
    String? selectedText,
  }) {
    return NoteModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      style: style ?? this.style,
      isFavorite: isFavorite ?? this.isFavorite,
      linkedText: linkedText ?? this.linkedText,
      aiInsights: aiInsights ?? this.aiInsights,
      selectedText: selectedText ?? this.selectedText,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        bookId,
        pageNumber,
        type,
        content,
        title,
        tags,
        createdAt,
        updatedAt,
        position,
        style,
        isFavorite,
        linkedText,
        aiInsights,
        selectedText,
      ];
}

/// Types of notes
@HiveType(typeId: 21)
enum NoteType {
  @HiveField(0)
  highlight,
  
  @HiveField(1)
  text,
  
  @HiveField(2)
  drawing,
  
  @HiveField(3)
  bookmark,
  
  @HiveField(4)
  question,
  
  @HiveField(5)
  summary,
}

/// Position of note on page
@HiveType(typeId: 22)
@JsonSerializable()
class NotePosition extends Equatable {
  @HiveField(0)
  final double x; // X coordinate (0-1, relative to page width)
  
  @HiveField(1)
  final double y; // Y coordinate (0-1, relative to page height)
  
  @HiveField(2)
  final double? width; // Width for highlights (0-1, relative to page width)
  
  @HiveField(3)
  final double? height; // Height for highlights (0-1, relative to page height)
  
  @HiveField(4)
  final int? startOffset; // Character offset for text selection
  
  @HiveField(5)
  final int? endOffset; // End character offset for text selection
  
  const NotePosition({
    required this.x,
    required this.y,
    this.width,
    this.height,
    this.startOffset,
    this.endOffset,
  });
  
  factory NotePosition.fromJson(Map<String, dynamic> json) => 
      _$NotePositionFromJson(json);
  
  Map<String, dynamic> toJson() => _$NotePositionToJson(this);
  
  /// Check if position represents a text selection
  bool get isTextSelection => startOffset != null && endOffset != null;
  
  /// Check if position represents an area selection
  bool get isAreaSelection => width != null && height != null;
  
  NotePosition copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    int? startOffset,
    int? endOffset,
  }) {
    return NotePosition(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
    );
  }
  
  @override
  List<Object?> get props => [x, y, width, height, startOffset, endOffset];
}

/// Visual style for notes
@HiveType(typeId: 23)
@JsonSerializable()
class NoteStyle extends Equatable {
  @HiveField(0)
  final String color; // Hex color code
  
  @HiveField(1)
  final double opacity;
  
  @HiveField(2)
  final double fontSize;
  
  @HiveField(3)
  final String fontFamily;
  
  @HiveField(4)
  final bool isBold;
  
  @HiveField(5)
  final bool isItalic;
  
  @HiveField(6)
  final HighlightStyle? highlightStyle;
  
  const NoteStyle({
    this.color = '#FFEB3B', // Default yellow
    this.opacity = 0.3,
    this.fontSize = 14.0,
    this.fontFamily = 'Inter',
    this.isBold = false,
    this.isItalic = false,
    this.highlightStyle,
  });
  
  factory NoteStyle.fromJson(Map<String, dynamic> json) => 
      _$NoteStyleFromJson(json);
  
  Map<String, dynamic> toJson() => _$NoteStyleToJson(this);
  
  /// Create default highlight style
  factory NoteStyle.highlight({String color = '#FFEB3B'}) {
    return NoteStyle(
      color: color,
      opacity: 0.3,
      highlightStyle: HighlightStyle.background,
    );
  }
  
  /// Create default text note style
  factory NoteStyle.textNote({String color = '#2196F3'}) {
    return NoteStyle(
      color: color,
      opacity: 1.0,
      fontSize: 14.0,
    );
  }
  
  NoteStyle copyWith({
    String? color,
    double? opacity,
    double? fontSize,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    HighlightStyle? highlightStyle,
  }) {
    return NoteStyle(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      highlightStyle: highlightStyle ?? this.highlightStyle,
    );
  }
  
  @override
  List<Object?> get props => [
        color,
        opacity,
        fontSize,
        fontFamily,
        isBold,
        isItalic,
        highlightStyle,
      ];
}

/// Highlight style options
@HiveType(typeId: 24)
enum HighlightStyle {
  @HiveField(0)
  background,
  
  @HiveField(1)
  underline,
  
  @HiveField(2)
  strikethrough,
  
  @HiveField(3)
  border,
}

/// AI-generated insights for notes
@HiveType(typeId: 25)
@JsonSerializable()
class AiInsights extends Equatable {
  @HiveField(0)
  final String? summary; // AI-generated summary
  
  @HiveField(1)
  final List<String> relatedConcepts; // Related topics/concepts
  
  @HiveField(2)
  final List<String> keyTerms; // Important terms extracted
  
  @HiveField(3)
  final String? explanation; // Simplified explanation
  
  @HiveField(4)
  final List<String> practiceQuestions; // Generated practice questions
  
  @HiveField(5)
  final double confidenceScore; // AI confidence (0-1)
  
  @HiveField(6)
  final DateTime generatedAt;
  
  const AiInsights({
    this.summary,
    this.relatedConcepts = const [],
    this.keyTerms = const [],
    this.explanation,
    this.practiceQuestions = const [],
    this.confidenceScore = 0.0,
    required this.generatedAt,
  });
  
  factory AiInsights.fromJson(Map<String, dynamic> json) => 
      _$AiInsightsFromJson(json);
  
  Map<String, dynamic> toJson() => _$AiInsightsToJson(this);
  
  /// Check if insights are reliable based on confidence score
  bool get isReliable => confidenceScore >= 0.7;
  
  /// Check if insights have content
  bool get hasContent {
    return summary != null ||
           relatedConcepts.isNotEmpty ||
           keyTerms.isNotEmpty ||
           explanation != null ||
           practiceQuestions.isNotEmpty;
  }
  
  AiInsights copyWith({
    String? summary,
    List<String>? relatedConcepts,
    List<String>? keyTerms,
    String? explanation,
    List<String>? practiceQuestions,
    double? confidenceScore,
    DateTime? generatedAt,
  }) {
    return AiInsights(
      summary: summary ?? this.summary,
      relatedConcepts: relatedConcepts ?? this.relatedConcepts,
      keyTerms: keyTerms ?? this.keyTerms,
      explanation: explanation ?? this.explanation,
      practiceQuestions: practiceQuestions ?? this.practiceQuestions,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        summary,
        relatedConcepts,
        keyTerms,
        explanation,
        practiceQuestions,
        confidenceScore,
        generatedAt,
      ];
}

/// Note collection for organizing related notes
@HiveType(typeId: 26)
@JsonSerializable()
class NoteCollection extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final List<String> noteIds;
  
  @HiveField(4)
  final List<String> tags;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime updatedAt;
  
  @HiveField(7)
  final String color; // Collection color theme
  
  const NoteCollection({
    required this.id,
    required this.name,
    this.description,
    this.noteIds = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color = '#2196F3',
  });
  
  factory NoteCollection.fromJson(Map<String, dynamic> json) => 
      _$NoteCollectionFromJson(json);
  
  Map<String, dynamic> toJson() => _$NoteCollectionToJson(this);
  
  /// Get number of notes in collection
  int get noteCount => noteIds.length;
  
  /// Check if collection is empty
  bool get isEmpty => noteIds.isEmpty;
  
  NoteCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? noteIds,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return NoteCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      noteIds: noteIds ?? this.noteIds,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        name,
        description,
        noteIds,
        tags,
        createdAt,
        updatedAt,
        color,
      ];
}
