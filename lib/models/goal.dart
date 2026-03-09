class Goal {
  final int? id;
  final String title;
  final String? description;
  final int? categoryId;
  final int durationDays;
  final DateTime startDate;
  final String status;

  Goal({
    this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.durationDays,
    required this.startDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'duration_days': durationDays,
      'start_date': startDate.toIso8601String(),
      'status': status,
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
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
    );
  }
}
