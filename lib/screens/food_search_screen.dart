import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';
import 'admin_food_screen.dart';

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
    'Rice & Grains',
    'Soups & Stews',
    'Swallow / Tubers',
    'Proteins / Meats',
    'Sides & Snacks',
    'Beverages',
  ];

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _selectedCategory == 'All'
        ? foodProvider.searchResults
        : foodProvider.searchResults.where((f) => f.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('West African Food Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'Admin Add Food',
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
              onChanged: (val) => foodProvider.searchFood(val),
              decoration: InputDecoration(
                hintText: 'Search Jollof, Egusi, Amala, Suya...',
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          foodProvider.searchFood('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Category Chips Filter
          SizedBox(
            height: 48,
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
                    selectedColor: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

          // Food Items List
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text('No West African foods found matching query.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final food = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(food.category),
                                    color: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                        _buildMacroBadge('P: ${food.protein.round()}g', AppColors.darkGreenAccent),
                                        const SizedBox(width: 6),
                                        _buildMacroBadge('C: ${food.carbs.round()}g', isDark ? AppColors.darkBlueAccent : AppColors.lightBluePrimary),
                                        const SizedBox(width: 6),
                                        _buildMacroBadge('F: ${food.fat.round()}g', isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange),
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
                                      color: isDark ? AppColors.darkGreenAccent : AppColors.lightBluePrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => _showLogMealDialog(context, food),
                                    child: const Text('Log Meal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
                      color: AppColors.darkGreenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Calories:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${(food.calories * selectedServings).round()} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkGreenAccent),
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
                        backgroundColor: AppColors.darkGreenAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Provider.of<FoodProvider>(context, listen: false).logMeal(
                          food: food,
                          mealType: selectedMealType,
                          servings: selectedServings,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logged ${food.name} (${selectedServings}x) to $selectedMealType!')),
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
