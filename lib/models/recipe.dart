import 'dart:convert';

class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String? ?? 'portion',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Recipe {
  final int? id;
  final String name;
  final String category;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int defaultServings;
  final double caloriesPerServing;
  final double protein;
  final double carbs;
  final double fat;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final bool isFavorite;
  final bool isCustom;

  Recipe({
    this.id,
    required this.name,
    required this.category,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.defaultServings,
    required this.caloriesPerServing,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.instructions,
    this.imageUrl = '',
    this.isFavorite = false,
    this.isCustom = false,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? category,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? defaultServings,
    double? caloriesPerServing,
    double? protein,
    double? carbs,
    double? fat,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    String? imageUrl,
    bool? isFavorite,
    bool? isCustom,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      defaultServings: defaultServings ?? this.defaultServings,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'default_servings': defaultServings,
      'calories_per_serving': caloriesPerServing,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients_json': jsonEncode(ingredients.map((e) => e.toMap()).toList()),
      'instructions_json': jsonEncode(instructions),
      'image_url': imageUrl,
      'is_favorite': isFavorite ? 1 : 0,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    List<RecipeIngredient> parsedIngredients = [];
    if (map['ingredients_json'] != null) {
      try {
        final decoded = jsonDecode(map['ingredients_json'] as String) as List;
        parsedIngredients = decoded.map((e) => RecipeIngredient.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<String> parsedInstructions = [];
    if (map['instructions_json'] != null) {
      try {
        final decoded = jsonDecode(map['instructions_json'] as String) as List;
        parsedInstructions = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Untitled Recipe',
      category: map['category'] as String? ?? 'Main',
      prepTimeMinutes: (map['prep_time_minutes'] as int?) ?? 20,
      cookTimeMinutes: (map['cook_time_minutes'] as int?) ?? 30,
      defaultServings: (map['default_servings'] as int?) ?? 2,
      caloriesPerServing: (map['calories_per_serving'] as num?)?.toDouble() ?? 400.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 20.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 45.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 12.0,
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
      imageUrl: map['image_url'] as String? ?? '',
      isFavorite: (map['is_favorite'] as int?) == 1,
      isCustom: (map['is_custom'] as int?) == 1,
    );
  }
}
