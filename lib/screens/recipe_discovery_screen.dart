import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../widgets/external_animation_view.dart';
import '../widgets/data_load_error.dart';
import 'recipe_detail_screen.dart';
import 'recipe_builder_screen.dart';

class RecipeDiscoveryScreen extends StatefulWidget {
  const RecipeDiscoveryScreen({super.key});

  @override
  State<RecipeDiscoveryScreen> createState() => _RecipeDiscoveryScreenState();
}

class _RecipeDiscoveryScreenState extends State<RecipeDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, RecipeProvider provider) {
    double tempMaxCalories = provider.maxCaloriesFilter ?? 600.0;
    double tempMinProtein = provider.minProteinFilter ?? 0.0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Recipes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Calories / Serving:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${tempMaxCalories.round()} kcal', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
                    ],
                  ),
                  Slider(
                    value: tempMaxCalories,
                    min: 200,
                    max: 800,
                    divisions: 12,
                    label: '${tempMaxCalories.round()} kcal',
                    onChanged: (v) => setModalState(() => tempMaxCalories = v),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Protein:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${tempMinProtein.round()}g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                    ],
                  ),
                  Slider(
                    value: tempMinProtein,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    label: '${tempMinProtein.round()}g',
                    onChanged: (v) => setModalState(() => tempMinProtein = v),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                      onPressed: () {
                        provider.setNutrientFilters(
                          maxCalories: tempMaxCalories,
                          minProtein: tempMinProtein > 0 ? tempMinProtein : null,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipes = recipeProvider.filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Discovery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter by macros',
            onPressed: () => _showFilterModal(context, recipeProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create Custom Recipe',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeBuilderScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => recipeProvider.searchRecipes(val),
              decoration: InputDecoration(
                hintText: 'Search authentic recipes by name or ingredient...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          recipeProvider.searchRecipes('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Categories Horizontal Filter Bar
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: recipeProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = recipeProvider.categories[index];
                final isSelected = recipeProvider.selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primaryAccentDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                    onSelected: (_) => recipeProvider.selectCategory(cat),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Recipes List
          Expanded(
            child: recipeProvider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExternalAnimationView(
                          assetPath: 'assets/animations/loading.json',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 12),
                        const Text('Loading authentic recipes...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  )
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
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                recipeProvider.clearFilters();
                              },
                              child: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return _buildRecipeCard(context, recipe, recipeProvider, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, RecipeProvider provider, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recipe.category,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: recipe.isFavorite ? Colors.redAccent : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => provider.toggleFavorite(recipe),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${recipe.prepTimeMinutes + recipe.cookTimeMinutes} mins', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 14),
                  const Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${recipe.defaultServings} servings', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMiniBadge('P: ${recipe.protein.round()}g', AppColors.accentGreen),
                      const SizedBox(width: 6),
                      _buildMiniBadge('C: ${recipe.carbs.round()}g', AppColors.accentBlue),
                      const SizedBox(width: 6),
                      _buildMiniBadge('F: ${recipe.fat.round()}g', AppColors.accentAmber),
                    ],
                  ),
                  Text(
                    '${recipe.caloriesPerServing.round()} kcal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
}
