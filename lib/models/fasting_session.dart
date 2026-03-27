import 'dart:convert';

class FastingSession {
  final int? id;
  final int journalEntryId;
  final DateTime? fastStartedAt;
  final DateTime? eatingStartedAt;
  final DateTime? eatingEndedAt;
  final double? actualFastingHours;
  final List<String> feelingTags;
  final String? breakNote;

  FastingSession({
    this.id,
    required this.journalEntryId,
    this.fastStartedAt,
    this.eatingStartedAt,
    this.eatingEndedAt,
    this.actualFastingHours,
    this.feelingTags = const [],
    this.breakNote,
  });

  bool get achievedTarget {
    if (actualFastingHours == null) return false;
    return true;
  }

  double achievementRatio(double targetHours) {
    if (actualFastingHours == null) return 0.0;
    return (actualFastingHours! / targetHours).clamp(0.0, 1.5);
  }

  String get formattedActualHours {
    if (actualFastingHours == null) return '--';
    final hours = actualFastingHours!.floor();
    final minutes = ((actualFastingHours! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'fast_started_at': fastStartedAt?.toIso8601String(),
      'eating_started_at': eatingStartedAt?.toIso8601String(),
      'eating_ended_at': eatingEndedAt?.toIso8601String(),
      'actual_fasting_hours': actualFastingHours,
      'feeling_tags': feelingTags.isEmpty ? null : jsonEncode(feelingTags),
      'break_note': breakNote,
    };
  }

  factory FastingSession.fromMap(Map<String, dynamic> map) {
    List<String> tags = [];
    if (map['feeling_tags'] != null) {
      final decoded = jsonDecode(map['feeling_tags'] as String);
      if (decoded is List) {
        tags = decoded.map((e) => e.toString()).toList();
      }
    }

    return FastingSession(
      id: map['id'] as int?,
      journalEntryId: map['journal_entry_id'] as int,
      fastStartedAt: map['fast_started_at'] != null
          ? DateTime.parse(map['fast_started_at'] as String)
          : null,
      eatingStartedAt: map['eating_started_at'] != null
          ? DateTime.parse(map['eating_started_at'] as String)
          : null,
      eatingEndedAt: map['eating_ended_at'] != null
          ? DateTime.parse(map['eating_ended_at'] as String)
          : null,
      actualFastingHours: map['actual_fasting_hours'] as double?,
      feelingTags: tags,
      breakNote: map['break_note'] as String?,
    );
  }

  FastingSession copyWith({
    int? id,
    int? journalEntryId,
    DateTime? fastStartedAt,
    DateTime? eatingStartedAt,
    DateTime? eatingEndedAt,
    double? actualFastingHours,
    List<String>? feelingTags,
    String? breakNote,
  }) {
    return FastingSession(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      fastStartedAt: fastStartedAt ?? this.fastStartedAt,
      eatingStartedAt: eatingStartedAt ?? this.eatingStartedAt,
      eatingEndedAt: eatingEndedAt ?? this.eatingEndedAt,
      actualFastingHours: actualFastingHours ?? this.actualFastingHours,
      feelingTags: feelingTags ?? this.feelingTags,
      breakNote: breakNote ?? this.breakNote,
    );
  }
}
