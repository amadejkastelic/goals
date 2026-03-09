import 'dart:typed_data';

class MediaAttachment {
  final int? id;
  final int journalEntryId;
  final String type;
  final Uint8List data;
  final DateTime createdAt;

  MediaAttachment({
    this.id,
    required this.journalEntryId,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'type': type,
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MediaAttachment.fromMap(Map<String, dynamic> map) {
    return MediaAttachment(
      id: map['id'] as int?,
      journalEntryId: map['journal_entry_id'] as int,
      type: map['type'] as String,
      data: map['data'] as Uint8List,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
