import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/recipe_provider.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/meal_success_overlay.dart';
import '../widgets/external_animation_view.dart';
import '../widgets/data_load_error.dart';
import 'ai_food_scanner_screen.dart';
import 'manual_food_entry_screen.dart';
import 'admin_food_screen.dart';
import 'recipe_detail_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Recipes 🍲',
    'Rice & Grains',
    'Soups & Stews',
    'Swallow / Tubers',
    'Proteins / Meats',
    'Sides & Snacks',
    'Beverages',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isRecipesTab = _selectedCategory == 'Recipes 🍲';
    final filteredList = _selectedCategory == 'All'
        ? foodProvider.searchResults
        : foodProvider.searchResults.where((f) => f.category == _selectedCategory).toList();
    final recipeQuery = _searchController.text.trim().toLowerCase();
    final recipes = recipeProvider.allRecipes.where((recipe) {
      return recipeQuery.isEmpty ||
          recipe.name.toLowerCase().contains(recipeQuery) ||
          recipe.category.toLowerCase().contains(recipeQuery) ||
          recipe.ingredients.any((ingredient) => ingredient.name.toLowerCase().contains(recipeQuery));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Database & Diary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Food Scanner Demo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiFoodScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Manual Food Entry',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManualFoodEntryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Admin Database Manager',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminFoodScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                foodProvider.searchFood(val);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search foods, Jollof, Egusi, Amala, Recipes...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          foodProvider.searchFood('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Category Chips Filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppColors.primaryAccentDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Food Items & Recipes List
          Expanded(
            child: isRecipesTab
                ? (recipeProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : recipeProvider.loadError != null
                    ? DataLoadError(message: recipeProvider.loadError!, onRetry: recipeProvider.loadRecipes)
                    : recipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExternalAnimationView(
                              assetPath: 'assets/animations/empty.json',
                              width: 90,
                              height: 90,
                            ),
                            const SizedBox(height: 12),
                            const Text('No recipes found matching query', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(Icons.menu_book_rounded, color: AppColors.primaryAccent, size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${recipe.caloriesPerServing.round()} kcal • ${recipe.defaultServings} servings • ${recipe.category}',
                                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ))
                : (foodProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : foodProvider.loadError != null
                    ? DataLoadError(message: foodProvider.loadError!, onRetry: foodProvider.loadInitialData)
                    : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExternalAnimationView(
                              assetPath: 'assets/animations/empty.json',
                              width: 90,
                              height: 90,
                            ),
                            const SizedBox(height: 12),
                            const Text('No foods found matching query', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add as Custom Food'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ManualFoodEntryScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final food = filteredList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getCategoryIcon(food.category),
                                        color: AppColors.primaryAccent,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          food.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${food.servingUnit} • ${food.category}',
                                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _buildMacroBadge('P: ${food.protein.round()}g', AppColors.accentGreen),
                                            const SizedBox(width: 6),
                                            _buildMacroBadge('C: ${food.carbs.round()}g', AppColors.accentBlue),
                                            const SizedBox(width: 6),
                                            _buildMacroBadge('F: ${food.fat.round()}g', AppColors.accentAmber),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${food.calories.round()} kcal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      BouncingButton(
                                        onTap: () => _showLogMealDialog(context, food),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryAccent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('Log Meal', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showLogMealDialog(BuildContext context, Food food) {
    String selectedMealType = 'Lunch';
    double selectedServings = 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log Meal: ${food.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${food.calories.round()} kcal per ${food.servingUnit}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 20),

                  const Text('Select Meal Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                      final isSel = selectedMealType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSel,
                        selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedMealType = type);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Serving Portion', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${selectedServings.toStringAsFixed(1)}x serving', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: selectedServings,
                    min: 0.5,
                    max: 4.0,
                    divisions: 7,
                    label: '${selectedServings.toStringAsFixed(1)}x',
                    onChanged: (val) {
                      setModalState(() => selectedServings = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Calculated totals preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Calories:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${(food.calories * selectedServings).round()} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accentGreen),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccentDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Provider.of<FoodProvider>(context, listen: false).logMeal(
                          food: food,
                          mealType: selectedMealType,
                          servings: selectedServings,
                        );
                        Navigator.pop(ctx);

                        MealSuccessOverlay.show(
                          context,
                          title: food.name,
                          mealType: selectedMealType,
                          calories: food.calories * selectedServings,
                          protein: food.protein * selectedServings,
                          carbs: food.carbs * selectedServings,
                          fat: food.fat * selectedServings,
                        );
                      },
                      child: const Text('Confirm & Log Meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rice & Grains':
        return Icons.rice_bowl_rounded;
      case 'Soups & Stews':
        return Icons.soup_kitchen_rounded;
      case 'Swallow / Tubers':
        return Icons.bakery_dining_rounded;
      case 'Proteins / Meats':
        return Icons.kebab_dining_rounded;
      case 'Sides & Snacks':
        return Icons.fastfood_rounded;
      case 'Beverages':
        return Icons.local_drink_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
