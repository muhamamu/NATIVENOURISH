import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/recipe.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double? _maxCaloriesFilter;
  double? _minProteinFilter;

  List<Recipe> get allRecipes => _allRecipes;
  List<Recipe> get filteredRecipes => _filteredRecipes;
  List<Recipe> get favoriteRecipes => _allRecipes.where((r) => r.isFavorite).toList();
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double? get maxCaloriesFilter => _maxCaloriesFilter;
  double? get minProteinFilter => _minProteinFilter;

  final List<String> categories = [
    'All',
    'Rice & Grains',
    'Soups & Stews',
    'Proteins / Meats',
    'Breakfast / Snacks',
    'Seafood & Meals',
  ];

  RecipeProvider() {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners();
    _allRecipes = await DatabaseHelper.instance.getAllRecipes();
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void searchRecipes(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setNutrientFilters({double? maxCalories, double? minProtein}) {
    _maxCaloriesFilter = maxCalories;
    _minProteinFilter = minProtein;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _maxCaloriesFilter = null;
    _minProteinFilter = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRecipes = _allRecipes.where((recipe) {
      final matchesQuery = _searchQuery.isEmpty ||
          recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredients.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' || recipe.category == _selectedCategory;

      final matchesCalories = _maxCaloriesFilter == null || recipe.caloriesPerServing <= _maxCaloriesFilter!;

      final matchesProtein = _minProteinFilter == null || recipe.protein >= _minProteinFilter!;

      return matchesQuery && matchesCategory && matchesCalories && matchesProtein;
    }).toList();
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    if (recipe.id == null) return;
    final newStatus = !recipe.isFavorite;
    await DatabaseHelper.instance.toggleFavoriteRecipe(recipe.id!, newStatus);

    final index = _allRecipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _allRecipes[index] = recipe.copyWith(isFavorite: newStatus);
      _applyFilters();
      notifyListeners();
    }
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

  Future<void> addCustomRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.insertRecipe(recipe);
    await loadRecipes();
  }

  Future<void> deleteRecipe(int id) async {
    await DatabaseHelper.instance.deleteRecipe(id);
    await loadRecipes();
  }
}
