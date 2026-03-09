class JournalEntry {
  final int? id;
  final int goalId;
  final int dayNumber;
  final DateTime date;
  final String? content;
  final String? moodEmoji;

  JournalEntry({
    this.id,
    required this.goalId,
    required this.dayNumber,
    required this.date,
    this.content,
    this.moodEmoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'day_number': dayNumber,
      'date': date.toIso8601String(),
      'content': content,
      'mood_emoji': moodEmoji,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      dayNumber: map['day_number'] as int,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String?,
      moodEmoji: map['mood_emoji'] as String?,
    );
  }
}
