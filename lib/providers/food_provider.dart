import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/food.dart';
import '../models/meal_log.dart';

class FoodProvider extends ChangeNotifier {
  List<Food> _allFoods = [];
  List<Food> _searchResults = [];
  List<MealLog> _todayMealLogs = [];
  bool _isLoading = false;

  List<Food> get allFoods => _allFoods;
  List<Food> get searchResults => _searchResults;
  List<MealLog> get todayMealLogs => _todayMealLogs;
  bool get isLoading => _isLoading;

  String get _todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  double get todayCalories => _todayMealLogs.fold(0.0, (sum, item) => sum + item.totalCalories);
  double get todayProtein => _todayMealLogs.fold(0.0, (sum, item) => sum + item.protein);
  double get todayCarbs => _todayMealLogs.fold(0.0, (sum, item) => sum + item.carbs);
  double get todayFat => _todayMealLogs.fold(0.0, (sum, item) => sum + item.fat);

  List<MealLog> getMealLogsByType(String type) {
    return _todayMealLogs.where((log) => log.mealType.toLowerCase() == type.toLowerCase()).toList();
  }

  FoodProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _allFoods = await DatabaseHelper.instance.getAllFoods();
    _searchResults = List.from(_allFoods);
    await loadTodayMealLogs();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTodayMealLogs() async {
    _todayMealLogs = await DatabaseHelper.instance.getMealLogsByDate(_todayDateStr);
    notifyListeners();
  }

  void searchFood(String query) {
    if (query.trim().isEmpty) {
      _searchResults = List.from(_allFoods);
    } else {
      final q = query.toLowerCase();
      _searchResults = _allFoods.where((f) {
        return f.name.toLowerCase().contains(q) || f.category.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> logMeal({
    required Food food,
    required String mealType,
    required double servings,
  }) async {
    final newLog = MealLog(
      foodId: food.id ?? 0,
      foodName: food.name,
      mealType: mealType,
      servings: servings,
      totalCalories: food.calories * servings,
      protein: food.protein * servings,
      carbs: food.carbs * servings,
      fat: food.fat * servings,
      loggedAt: _todayDateStr,
    );

    await DatabaseHelper.instance.insertMealLog(newLog);
    await loadTodayMealLogs();
  }

  Future<void> deleteMealLog(int id) async {
    await DatabaseHelper.instance.deleteMealLog(id);
    await loadTodayMealLogs();
  }

  Future<void> addCustomFood(Food food) async {
    await DatabaseHelper.instance.insertFood(food);
    await loadInitialData();
  }

  Future<void> deleteCustomFood(int id) async {
    await DatabaseHelper.instance.deleteFood(id);
    await loadInitialData();
  }
}
