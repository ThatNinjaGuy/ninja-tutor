import 'package:equatable/equatable.dart';

/// Simple bookmark model
class BookmarkModel extends Equatable {
  final String id;
  final String bookId;
  final String userId;
  final int pageNumber;
  final DateTime createdAt;
  final String? note;
  
  const BookmarkModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.pageNumber,
    required this.createdAt,
    this.note,
  });
  
  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      userId: json['user_id'] as String,
      pageNumber: json['page_number'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      note: json['note'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'page_number': pageNumber,
      'created_at': createdAt.toIso8601String(),
      if (note != null) 'note': note,
    };
  }
  
  @override
  List<Object?> get props => [id, bookId, userId, pageNumber, createdAt, note];
}

