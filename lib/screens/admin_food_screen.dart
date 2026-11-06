import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';

class AdminFoodScreen extends StatefulWidget {
  const AdminFoodScreen({super.key});

  @override
  State<AdminFoodScreen> createState() => _AdminFoodScreenState();
}

class _AdminFoodScreenState extends State<AdminFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: '1 portion (250g)');
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String _selectedCategory = 'Rice & Grains';

  final List<String> _categories = [
    'Rice & Grains',
    'Soups & Stews',
    'Swallow / Tubers',
    'Proteins / Meats',
    'Sides & Snacks',
    'Beverages',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double get _p => double.tryParse(_proteinController.text) ?? 0.0;
  double get _c => double.tryParse(_carbsController.text) ?? 0.0;
  double get _f => double.tryParse(_fatController.text) ?? 0.0;
  double get _computedCalories => (_p * 4.0) + (_c * 4.0) + (_f * 9.0);

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customFoods = foodProvider.allFoods.where((f) => f.isCustom).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Database Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.accentGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage and expand verified West African foods & nutritional values in the local SQLite database. Calories are strictly calculated via the Atwater equation.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add Food Composition Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_computedCalories.round()} kcal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Dish Name (e.g. Kilishi, Banga Soup)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter dish name' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Serving Portion Unit (e.g. 1 plate, 1 wrap)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter serving unit' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _proteinController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Protein (g)', prefixIcon: Icon(Icons.fitness_center_rounded, color: AppColors.accentGreen)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _carbsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Carbs (g)', prefixIcon: Icon(Icons.grain_rounded, color: AppColors.accentBlue)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _fatController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Fat (g)', prefixIcon: Icon(Icons.opacity_rounded, color: AppColors.accentAmber)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
                            if (_formKey.currentState!.validate()) {
                              final newFood = Food(
                                name: _nameController.text.trim(),
                                category: _selectedCategory,
                                servingUnit: _unitController.text.trim(),
                                calories: _computedCalories,
                                protein: _p,
                                carbs: _c,
                                fat: _f,
                                isCustom: true,
                              );

                              foodProvider.addCustomFood(newFood);

                              _nameController.clear();
                              _proteinController.clear();
                              _carbsController.clear();
                              _fatController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved "${newFood.name}" with ${_computedCalories.round()} kcal (Atwater certified).')),
                              );
                            }
                          },
                          child: const Text('Save Dish to Database', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('Custom Database Dishes (${customFoods.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            customFoods.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: const Center(
                      child: Text('No custom dishes added yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customFoods.length,
                    itemBuilder: (context, index) {
                      final food = customFoods[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${food.category} • ${food.calories.round()} kcal • ${food.servingUnit}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            onPressed: () {
                              if (food.id != null) foodProvider.deleteCustomFood(food.id!);
                            },
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
