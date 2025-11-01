import 'package:equatable/equatable.dart';

/// Model representing a persisted highlight annotation on a PDF page.
class HighlightModel extends Equatable {
  const HighlightModel({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.text,
    required this.color,
    this.positionData,
    this.createdAt,
  });

  final String id;
  final String bookId;
  final int pageNumber;
  final String text;
  final String color;
  final String? positionData;
  final DateTime? createdAt;

  factory HighlightModel.fromJson(
    Map<String, dynamic> json, {
    required String bookId,
  }) {
    return HighlightModel(
      id: json['id'] as String,
      bookId: bookId,
      pageNumber: json['page_number'] as int,
      text: json['text'] as String,
      color: (json['color'] as String?) ?? 'yellow',
      positionData: json['position_data'] as String?,
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  HighlightModel copyWith({
    String? id,
    String? bookId,
    int? pageNumber,
    String? text,
    String? color,
    String? positionData,
    DateTime? createdAt,
  }) {
    return HighlightModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      text: text ?? this.text,
      color: color ?? this.color,
      positionData: positionData ?? this.positionData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        pageNumber,
        text,
        color,
        positionData,
        createdAt,
      ];
}

