class Food {
  final int? id;
  final String name;
  final String category;
  final String servingUnit;
  final double calories; // kcal per serving
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final bool isCustom;

  Food({
    this.id,
    required this.name,
    required this.category,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'serving_unit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      servingUnit: map['serving_unit'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      isCustom: (map['is_custom'] as int?) == 1,
    );
  }
}
