class MealLog {
  final int? id;
  final int foodId;
  final String foodName;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final double servings;
  final double totalCalories;
  final double protein;
  final double carbs;
  final double fat;
  final String loggedAt; // YYYY-MM-DD

  MealLog({
    this.id,
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.servings,
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_id': foodId,
      'food_name': foodName,
      'meal_type': mealType,
      'servings': servings,
      'total_calories': totalCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'logged_at': loggedAt,
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'] as int?,
      foodId: map['food_id'] as int,
      foodName: map['food_name'] as String,
      mealType: map['meal_type'] as String,
      servings: (map['servings'] as num).toDouble(),
      totalCalories: (map['total_calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      loggedAt: map['logged_at'] as String,
    );
  }
}
