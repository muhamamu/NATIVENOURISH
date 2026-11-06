import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/food.dart';
import '../models/meal_log.dart';

class FoodProvider extends ChangeNotifier {
  List<Food> _allFoods = [];
  List<Food> _searchResults = [];
  List<MealLog> _todayMealLogs = [];
  List<Map<String, dynamic>> _weeklySummary = [];
  bool _isLoading = false;
  String? _loadError;

  DateTime _selectedDate = DateTime.now();
  double _todayWaterMl = 0.0;

  List<Food> get allFoods => _allFoods;
  List<Food> get searchResults => _searchResults;
  List<MealLog> get todayMealLogs => _todayMealLogs;
  List<Map<String, dynamic>> get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  DateTime get selectedDate => _selectedDate;
  String get selectedDateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get selectedDateDisplay {
    final now = DateTime.now();
    if (_selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day) {
      return 'Today, ${DateFormat('MMM d').format(_selectedDate)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_selectedDate.year == yesterday.year && _selectedDate.month == yesterday.month && _selectedDate.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('MMM d').format(_selectedDate)}';
    }
    return DateFormat('EEE, MMM d').format(_selectedDate);
  }

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
  }

  double get todayCalories => _todayMealLogs.fold(0.0, (sum, item) => sum + item.totalCalories);
  double get todayProtein => _todayMealLogs.fold(0.0, (sum, item) => sum + item.protein);
  double get todayCarbs => _todayMealLogs.fold(0.0, (sum, item) => sum + item.carbs);
  double get todayFat => _todayMealLogs.fold(0.0, (sum, item) => sum + item.fat);
  double get todayWaterMl => _todayWaterMl;

  FoodProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _loadError = null;
    try {
      _allFoods = await DatabaseHelper.instance.getAllFoods();
      _searchResults = List.from(_allFoods);
      await loadDateMealLogs();
    } catch (error) {
      debugPrint('Could not load foods: $error');
      _loadError = 'Could not load foods. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    loadDateMealLogs();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadDateMealLogs();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    loadDateMealLogs();
  }

  Future<void> loadDateMealLogs() async {
    _todayMealLogs = await DatabaseHelper.instance.getMealLogsByDate(selectedDateStr);
    _todayWaterMl = await DatabaseHelper.instance.getWaterTotalByDate(selectedDateStr);
    _weeklySummary = await DatabaseHelper.instance.getWeeklyCalorieSummary();
    notifyListeners();
  }

  // --- MEAL TYPE FILTERING & METRICS ---
  List<MealLog> getMealLogsByType(String type) {
    return _todayMealLogs.where((log) => log.mealType.toLowerCase() == type.toLowerCase()).toList();
  }

  double getCaloriesByType(String type) {
    return getMealLogsByType(type).fold(0.0, (sum, item) => sum + item.totalCalories);
  }

  double getProteinByType(String type) {
    return getMealLogsByType(type).fold(0.0, (sum, item) => sum + item.protein);
  }

  double getCarbsByType(String type) {
    return getMealLogsByType(type).fold(0.0, (sum, item) => sum + item.carbs);
  }

  double getFatByType(String type) {
    return getMealLogsByType(type).fold(0.0, (sum, item) => sum + item.fat);
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
    String? customDateStr,
  }) async {
    final date = customDateStr ?? selectedDateStr;
    final newLog = MealLog(
      foodId: food.id ?? 0,
      foodName: food.name,
      mealType: mealType,
      servings: servings,
      totalCalories: food.calories * servings,
      protein: food.protein * servings,
      carbs: food.carbs * servings,
      fat: food.fat * servings,
      loggedAt: date,
    );

    await DatabaseHelper.instance.insertMealLog(newLog);
    await loadDateMealLogs();
  }

  Future<void> deleteMealLog(int id) async {
    await DatabaseHelper.instance.deleteMealLog(id);
    await loadDateMealLogs();
  }

  Future<void> addCustomFood(Food food) async {
    await DatabaseHelper.instance.insertFood(food);
    await loadInitialData();
  }

  Future<void> deleteCustomFood(int id) async {
    await DatabaseHelper.instance.deleteFood(id);
    await loadInitialData();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // --- HYDRATION ACTIONS ---
  Future<void> addWater(double amountMl) async {
    if (!amountMl.isFinite || amountMl <= 0) return;
    await DatabaseHelper.instance.insertWaterLog(amountMl, selectedDateStr);
    _todayWaterMl = await DatabaseHelper.instance.getWaterTotalByDate(selectedDateStr);
    notifyListeners();
  }

  Future<void> reduceWater(double amountMl) async {
    final date = selectedDateStr;
    await DatabaseHelper.instance.reduceWaterLog(amountMl, date);
    if (date == selectedDateStr) {
      _todayWaterMl = await DatabaseHelper.instance.getWaterTotalByDate(date);
      notifyListeners();
    }
  }

  Future<void> removeLastWater() async {
    await DatabaseHelper.instance.removeLastWaterEntry(selectedDateStr);
    _todayWaterMl = await DatabaseHelper.instance.getWaterTotalByDate(selectedDateStr);
    notifyListeners();
  }

  Future<void> clearWater() async {
    await DatabaseHelper.instance.clearWaterLogsByDate(selectedDateStr);
    _todayWaterMl = 0.0;
    notifyListeners();
  }
}
