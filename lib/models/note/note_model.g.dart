// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 20;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      bookId: fields[1] as String,
      pageNumber: fields[2] as int,
      type: fields[3] as NoteType,
      content: fields[4] as String,
      title: fields[5] as String?,
      tags: (fields[6] as List).cast<String>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      position: fields[9] as NotePosition,
      style: fields[10] as NoteStyle,
      isFavorite: fields[11] as bool,
      linkedText: fields[12] as String?,
      aiInsights: fields[13] as AiInsights?,
      selectedText: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.pageNumber)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.position)
      ..writeByte(10)
      ..write(obj.style)
      ..writeByte(11)
      ..write(obj.isFavorite)
      ..writeByte(12)
      ..write(obj.linkedText)
      ..writeByte(13)
      ..write(obj.aiInsights)
      ..writeByte(14)
      ..write(obj.selectedText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotePositionAdapter extends TypeAdapter<NotePosition> {
  @override
  final int typeId = 22;

  @override
  NotePosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotePosition(
      x: fields[0] as double,
      y: fields[1] as double,
      width: fields[2] as double?,
      height: fields[3] as double?,
      startOffset: fields[4] as int?,
      endOffset: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, NotePosition obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.startOffset)
      ..writeByte(5)
      ..write(obj.endOffset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotePositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteStyleAdapter extends TypeAdapter<NoteStyle> {
  @override
  final int typeId = 23;

  @override
  NoteStyle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteStyle(
      color: fields[0] as String,
      opacity: fields[1] as double,
      fontSize: fields[2] as double,
      fontFamily: fields[3] as String,
      isBold: fields[4] as bool,
      isItalic: fields[5] as bool,
      highlightStyle: fields[6] as HighlightStyle?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteStyle obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.color)
      ..writeByte(1)
      ..write(obj.opacity)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.fontFamily)
      ..writeByte(4)
      ..write(obj.isBold)
      ..writeByte(5)
      ..write(obj.isItalic)
      ..writeByte(6)
      ..write(obj.highlightStyle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiInsightsAdapter extends TypeAdapter<AiInsights> {
  @override
  final int typeId = 25;

  @override
  AiInsights read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiInsights(
      summary: fields[0] as String?,
      relatedConcepts: (fields[1] as List).cast<String>(),
      keyTerms: (fields[2] as List).cast<String>(),
      explanation: fields[3] as String?,
      practiceQuestions: (fields[4] as List).cast<String>(),
      confidenceScore: fields[5] as double,
      generatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiInsights obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.summary)
      ..writeByte(1)
      ..write(obj.relatedConcepts)
      ..writeByte(2)
      ..write(obj.keyTerms)
      ..writeByte(3)
      ..write(obj.explanation)
      ..writeByte(4)
      ..write(obj.practiceQuestions)
      ..writeByte(5)
      ..write(obj.confidenceScore)
      ..writeByte(6)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiInsightsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteCollectionAdapter extends TypeAdapter<NoteCollection> {
  @override
  final int typeId = 26;

  @override
  NoteCollection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteCollection(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      noteIds: (fields[3] as List).cast<String>(),
      tags: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      color: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NoteCollection obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.noteIds)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteCollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteTypeAdapter extends TypeAdapter<NoteType> {
  @override
  final int typeId = 21;

  @override
  NoteType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoteType.highlight;
      case 1:
        return NoteType.text;
      case 2:
        return NoteType.drawing;
      case 3:
        return NoteType.bookmark;
      case 4:
        return NoteType.question;
      case 5:
        return NoteType.summary;
      default:
        return NoteType.highlight;
    }
  }

  @override
  void write(BinaryWriter writer, NoteType obj) {
    switch (obj) {
      case NoteType.highlight:
        writer.writeByte(0);
        break;
      case NoteType.text:
        writer.writeByte(1);
        break;
      case NoteType.drawing:
        writer.writeByte(2);
        break;
      case NoteType.bookmark:
        writer.writeByte(3);
        break;
      case NoteType.question:
        writer.writeByte(4);
        break;
      case NoteType.summary:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HighlightStyleAdapter extends TypeAdapter<HighlightStyle> {
  @override
  final int typeId = 24;

  @override
  HighlightStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HighlightStyle.background;
      case 1:
        return HighlightStyle.underline;
      case 2:
        return HighlightStyle.strikethrough;
      case 3:
        return HighlightStyle.border;
      default:
        return HighlightStyle.background;
    }
  }

  @override
  void write(BinaryWriter writer, HighlightStyle obj) {
    switch (obj) {
      case HighlightStyle.background:
        writer.writeByte(0);
        break;
      case HighlightStyle.underline:
        writer.writeByte(1);
        break;
      case HighlightStyle.strikethrough:
        writer.writeByte(2);
        break;
      case HighlightStyle.border:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => NoteModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      type: $enumDecode(_$NoteTypeEnumMap, json['type']),
      content: json['content'] as String,
      title: json['title'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      position: NotePosition.fromJson(json['position'] as Map<String, dynamic>),
      style: NoteStyle.fromJson(json['style'] as Map<String, dynamic>),
      isFavorite: json['isFavorite'] as bool? ?? false,
      linkedText: json['linkedText'] as String?,
      aiInsights: json['aiInsights'] == null
          ? null
          : AiInsights.fromJson(json['aiInsights'] as Map<String, dynamic>),
      selectedText: json['selected_text'] as String?,
    );

Map<String, dynamic> _$NoteModelToJson(NoteModel instance) => <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'pageNumber': instance.pageNumber,
      'type': _$NoteTypeEnumMap[instance.type]!,
      'content': instance.content,
      'title': instance.title,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'position': instance.position,
      'style': instance.style,
      'isFavorite': instance.isFavorite,
      'linkedText': instance.linkedText,
      'aiInsights': instance.aiInsights,
      'selected_text': instance.selectedText,
    };

const _$NoteTypeEnumMap = {
  NoteType.highlight: 'highlight',
  NoteType.text: 'text',
  NoteType.drawing: 'drawing',
  NoteType.bookmark: 'bookmark',
  NoteType.question: 'question',
  NoteType.summary: 'summary',
};

NotePosition _$NotePositionFromJson(Map<String, dynamic> json) => NotePosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      startOffset: (json['startOffset'] as num?)?.toInt(),
      endOffset: (json['endOffset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NotePositionToJson(NotePosition instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'startOffset': instance.startOffset,
      'endOffset': instance.endOffset,
    };

NoteStyle _$NoteStyleFromJson(Map<String, dynamic> json) => NoteStyle(
      color: json['color'] as String? ?? '#FFEB3B',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.3,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      highlightStyle:
          $enumDecodeNullable(_$HighlightStyleEnumMap, json['highlightStyle']),
    );

Map<String, dynamic> _$NoteStyleToJson(NoteStyle instance) => <String, dynamic>{
      'color': instance.color,
      'opacity': instance.opacity,
      'fontSize': instance.fontSize,
      'fontFamily': instance.fontFamily,
      'isBold': instance.isBold,
      'isItalic': instance.isItalic,
      'highlightStyle': _$HighlightStyleEnumMap[instance.highlightStyle],
    };

const _$HighlightStyleEnumMap = {
  HighlightStyle.background: 'background',
  HighlightStyle.underline: 'underline',
  HighlightStyle.strikethrough: 'strikethrough',
  HighlightStyle.border: 'border',
};

AiInsights _$AiInsightsFromJson(Map<String, dynamic> json) => AiInsights(
      summary: json['summary'] as String?,
      relatedConcepts: (json['relatedConcepts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      keyTerms: (json['keyTerms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      explanation: json['explanation'] as String?,
      practiceQuestions: (json['practiceQuestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$AiInsightsToJson(AiInsights instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'relatedConcepts': instance.relatedConcepts,
      'keyTerms': instance.keyTerms,
      'explanation': instance.explanation,
      'practiceQuestions': instance.practiceQuestions,
      'confidenceScore': instance.confidenceScore,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };

NoteCollection _$NoteCollectionFromJson(Map<String, dynamic> json) =>
    NoteCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      noteIds: (json['noteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      color: json['color'] as String? ?? '#2196F3',
    );

Map<String, dynamic> _$NoteCollectionToJson(NoteCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'noteIds': instance.noteIds,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'color': instance.color,
    };
