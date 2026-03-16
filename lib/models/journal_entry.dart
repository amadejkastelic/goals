import 'mfp_nutrition.dart';
import 'health_data.dart';

class JournalEntry {
  final int? id;
  final int goalId;
  final int dayNumber;
  final DateTime date;
  final String? content;
  final String? moodEmoji;
  final MFPNutrition? mfpNutrition;
  final HealthData? healthData;

  JournalEntry({
    this.id,
    required this.goalId,
    required this.dayNumber,
    required this.date,
    this.content,
    this.moodEmoji,
    this.mfpNutrition,
    this.healthData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'day_number': dayNumber,
      'date': date.toIso8601String(),
      'content': content,
      'mood_emoji': moodEmoji,
      'mfp_calories': mfpNutrition?.calories,
      'mfp_protein': mfpNutrition?.protein,
      'mfp_carbs': mfpNutrition?.carbs,
      'mfp_fat': mfpNutrition?.fat,
      'mfp_fiber': mfpNutrition?.fiber,
      'mfp_sodium': mfpNutrition?.sodium,
      'mfp_sugar': mfpNutrition?.sugar,
      'health_steps': healthData?.steps,
      'health_active_calories': healthData?.activeCalories,
      'health_heart_rate': healthData?.heartRate,
      'health_sleep_minutes': healthData?.sleepMinutes,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    MFPNutrition? nutrition;
    if (map['mfp_calories'] != null) {
      nutrition = MFPNutrition.fromMap(map);
    }

    HealthData? healthData;
    if (map['health_steps'] != null ||
        map['health_active_calories'] != null ||
        map['health_heart_rate'] != null ||
        map['health_sleep_minutes'] != null) {
      healthData = HealthData.fromMap(map);
    }

    return JournalEntry(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      dayNumber: map['day_number'] as int,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String?,
      moodEmoji: map['mood_emoji'] as String?,
      mfpNutrition: nutrition,
      healthData: healthData,
    );
  }

  JournalEntry copyWith({
    int? id,
    int? goalId,
    int? dayNumber,
    DateTime? date,
    String? content,
    String? moodEmoji,
    MFPNutrition? mfpNutrition,
    HealthData? healthData,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      content: content ?? this.content,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      mfpNutrition: mfpNutrition ?? this.mfpNutrition,
      healthData: healthData ?? this.healthData,
    );
  }
}
