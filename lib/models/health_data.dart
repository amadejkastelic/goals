class HealthData {
  final int? steps;
  final double? activeCalories;
  final double? heartRate;
  final int? sleepMinutes;

  const HealthData({
    this.steps,
    this.activeCalories,
    this.heartRate,
    this.sleepMinutes,
  });

  bool get hasData =>
      steps != null ||
      activeCalories != null ||
      heartRate != null ||
      sleepMinutes != null;

  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      steps: map['health_steps'] as int?,
      activeCalories: (map['health_active_calories'] as num?)?.toDouble(),
      heartRate: (map['health_heart_rate'] as num?)?.toDouble(),
      sleepMinutes: map['health_sleep_minutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'health_steps': steps,
      'health_active_calories': activeCalories,
      'health_heart_rate': heartRate,
      'health_sleep_minutes': sleepMinutes,
    };
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }

  String get formattedSteps => '${_formatNumber(steps ?? 0)} steps';
  String get formattedCalories =>
      '${activeCalories?.toStringAsFixed(0) ?? 0} cal';
  String get formattedHeartRate => '${heartRate?.toStringAsFixed(0) ?? 0} bpm';
  String get formattedSleep {
    if (sleepMinutes == null) return '0h 0m';
    final hours = sleepMinutes! ~/ 60;
    final mins = sleepMinutes! % 60;
    return '${hours}h ${mins}m';
  }

  HealthData copyWith({
    int? steps,
    double? activeCalories,
    double? heartRate,
    int? sleepMinutes,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      heartRate: heartRate ?? this.heartRate,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    );
  }
}
