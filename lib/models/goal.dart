import 'fasting_protocol.dart';

class Goal {
  final int? id;
  final String title;
  final String? description;
  final int? categoryId;
  final int durationDays;
  final DateTime startDate;
  final String status;
  final String goalType;
  final FastingProtocol? fastingProtocol;
  final double? fastingTargetHours;
  final String? eatingWindowStart;

  Goal({
    this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.durationDays,
    required this.startDate,
    this.status = 'active',
    this.goalType = 'regular',
    this.fastingProtocol,
    this.fastingTargetHours,
    this.eatingWindowStart,
  });

  bool get isFasting => goalType == 'fasting';

  double get effectiveFastingTargetHours {
    if (fastingTargetHours != null && fastingTargetHours! > 0) {
      return fastingTargetHours!;
    }
    if (fastingProtocol != null) {
      return fastingProtocol!.targetFastingHours;
    }
    return 16.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'duration_days': durationDays,
      'start_date': startDate.toIso8601String(),
      'status': status,
      'goal_type': goalType,
      'fasting_protocol': fastingProtocol?.name,
      'fasting_target_hours': fastingTargetHours,
      'eating_window_start': eatingWindowStart,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
      durationDays: map['duration_days'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      status: map['status'] as String,
      goalType: map['goal_type'] as String? ?? 'regular',
      fastingProtocol: map['fasting_protocol'] != null
          ? FastingProtocol.fromName(map['fasting_protocol'] as String)
          : null,
      fastingTargetHours: map['fasting_target_hours'] as double?,
      eatingWindowStart: map['eating_window_start'] as String?,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    int? categoryId,
    int? durationDays,
    DateTime? startDate,
    String? status,
    String? goalType,
    FastingProtocol? fastingProtocol,
    double? fastingTargetHours,
    String? eatingWindowStart,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      goalType: goalType ?? this.goalType,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      fastingTargetHours: fastingTargetHours ?? this.fastingTargetHours,
      eatingWindowStart: eatingWindowStart ?? this.eatingWindowStart,
    );
  }
}
