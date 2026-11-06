import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/food.dart';
import '../providers/recipe_provider.dart';
import '../providers/food_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_success_overlay.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings;
  final Set<int> _checkedIngredients = {};
  String _selectedMealType = 'Lunch';

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.defaultServings;
  }

  void _logRecipeMeal() {
    final recipe = widget.recipe;
    final ratio = _servings / recipe.defaultServings;

    final food = Food(
      name: recipe.name,
      category: recipe.category,
      servingUnit: '1 serving (${recipe.caloriesPerServing.round()} kcal)',
      calories: recipe.caloriesPerServing,
      protein: recipe.protein,
      carbs: recipe.carbs,
      fat: recipe.fat,
      isCustom: true,
    );

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.logMeal(
      food: food,
      mealType: _selectedMealType,
      servings: ratio,
    );

    MealSuccessOverlay.show(
      context,
      title: recipe.name,
      mealType: _selectedMealType,
      calories: recipe.caloriesPerServing * ratio,
      protein: recipe.protein * ratio,
      carbs: recipe.carbs * ratio,
      fat: recipe.fat * ratio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentRecipe = recipeProvider.allRecipes.firstWhere(
      (r) => r.id == widget.recipe.id,
      orElse: () => widget.recipe,
    );

    final ratio = _servings / currentRecipe.defaultServings;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRecipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              currentRecipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: currentRecipe.isFavorite ? Colors.redAccent : (isDark ? Colors.white : Colors.black),
            ),
            tooltip: 'Favorite Recipe',
            onPressed: () => recipeProvider.toggleFavorite(currentRecipe),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER HERO CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF161822), Color(0xFF1D202D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xFFF9FAFB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentRecipe.category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${currentRecipe.prepTimeMinutes + currentRecipe.cookTimeMinutes} mins total',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentRecipe.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),

                  // Nutritional Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('${currentRecipe.caloriesPerServing.round()}', 'kcal / serv', AppColors.primaryOrange),
                      _buildMacroBadge('${currentRecipe.protein.round()}g', 'Protein', AppColors.accentGreen),
                      _buildMacroBadge('${currentRecipe.carbs.round()}g', 'Carbs', AppColors.accentBlue),
                      _buildMacroBadge('${currentRecipe.fat.round()}g', 'Fat', AppColors.accentAmber),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SERVING ADJUSTER BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Adjust Servings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primaryOrange),
                        onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                      ),
                      Text(
                        '$_servings portions',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryOrange),
                        onPressed: _servings < 12 ? () => setState(() => _servings++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- INGREDIENTS LIST WITH CHECKLIST ---
            Text('Ingredients (${currentRecipe.ingredients.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: currentRecipe.ingredients.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                itemBuilder: (context, index) {
                  final ing = currentRecipe.ingredients[index];
                  final adjustedAmount = (ing.amount * ratio);
                  final isChecked = _checkedIngredients.contains(index);

                  return CheckboxListTile(
                    title: Text(
                      ing.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(
                      '${adjustedAmount % 1 == 0 ? adjustedAmount.toInt() : adjustedAmount.toStringAsFixed(1)} ${ing.unit}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    value: isChecked,
                    activeColor: AppColors.accentGreen,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedIngredients.add(index);
                        } else {
                          _checkedIngredients.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- COOKING INSTRUCTIONS ---
            Text('Preparation Instructions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentRecipe.instructions.length,
              itemBuilder: (context, index) {
                final step = currentRecipe.instructions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOrange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 13, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // --- MEAL TYPE LOGGING SELECTOR ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Meal Type to Log:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                      final isSel = _selectedMealType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSel,
                        selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                        onSelected: (val) {
                          if (val) setState(() => _selectedMealType = type);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 1-TAP LOG TO FOOD DIARY BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.restaurant_rounded, color: Colors.white),
                label: Text(
                  'Log Recipe to Food Diary (${_servings}x)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _logRecipeMeal,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
