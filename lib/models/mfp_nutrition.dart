class MFPNutrition {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sodium;
  final double? sugar;

  const MFPNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
    this.sugar,
  });

  factory MFPNutrition.fromMap(Map<String, dynamic> map) {
    return MFPNutrition(
      calories: (map['mfp_calories'] as int?) ?? 0,
      protein: (map['mfp_protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['mfp_carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['mfp_fat'] as num?)?.toDouble() ?? 0,
      fiber: (map['mfp_fiber'] as num?)?.toDouble(),
      sodium: (map['mfp_sodium'] as num?)?.toDouble(),
      sugar: (map['mfp_sugar'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mfp_calories': calories,
      'mfp_protein': protein,
      'mfp_carbs': carbs,
      'mfp_fat': fat,
      'mfp_fiber': fiber,
      'mfp_sodium': sodium,
      'mfp_sugar': sugar,
    };
  }

  bool get hasData => calories > 0 || protein > 0 || carbs > 0 || fat > 0;

  String get formattedCalories => '$calories cal';
  String get formattedProtein => '${protein.toStringAsFixed(0)}g protein';
  String get formattedCarbs => '${carbs.toStringAsFixed(0)}g carbs';
  String get formattedFat => '${fat.toStringAsFixed(0)}g fat';
}
