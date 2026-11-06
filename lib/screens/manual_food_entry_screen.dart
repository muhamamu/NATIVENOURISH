import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food.dart';
import '../providers/food_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_success_overlay.dart';

class ManualFoodEntryScreen extends StatefulWidget {
  const ManualFoodEntryScreen({super.key});

  @override
  State<ManualFoodEntryScreen> createState() => _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends State<ManualFoodEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController(text: '1 serving (150g)');
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String _selectedCategory = 'Proteins / Meats';
  bool _logImmediately = true;
  String _mealType = 'Lunch';

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

  double get _protein => double.tryParse(_proteinController.text) ?? 0.0;
  double get _carbs => double.tryParse(_carbsController.text) ?? 0.0;
  double get _fat => double.tryParse(_fatController.text) ?? 0.0;

  /// Strict Atwater Scientific Standard:
  /// 4 kcal per gram of Protein
  /// 4 kcal per gram of Carbohydrate
  /// 9 kcal per gram of Fat
  /// Manual calorie override is completely disabled to eliminate human under-reporting bias.
  double get _calculatedCalories => (_protein * 4.0) + (_carbs * 4.0) + (_fat * 9.0);

  void _saveFood() {
    if (!_formKey.currentState!.validate()) return;

    final food = Food(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      servingUnit: _unitController.text.trim(),
      calories: _calculatedCalories,
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
      isCustom: true,
    );

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.addCustomFood(food);

    if (_logImmediately) {
      foodProvider.logMeal(
        food: food,
        mealType: _mealType,
        servings: 1.0,
      );
    }

    Navigator.pop(context);

    if (_logImmediately) {
      MealSuccessOverlay.show(
        context,
        title: food.name,
        mealType: _mealType,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${food.name}" with ${_calculatedCalories.round()} kcal (Atwater certified).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double cals = _calculatedCalories;
    final double p = _protein;
    final double c = _carbs;
    final double f = _fat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Food Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Nutritional Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'NUTRITIONAL PREVIEW',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 11, color: AppColors.primaryOrange),
                              SizedBox(width: 4),
                              Text(
                                'ATWATER VERIFIED',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'Custom Food Item',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      _unitController.text.isNotEmpty ? _unitController.text : '1 serving',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('${cals.round()}', 'kcal', AppColors.primaryOrange),
                        _buildStat('${p.toStringAsFixed(1)}g', 'Protein', AppColors.accentGreen),
                        _buildStat('${c.toStringAsFixed(1)}g', 'Carbs', AppColors.accentBlue),
                        _buildStat('${f.toStringAsFixed(1)}g', 'Fat', AppColors.accentAmber),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Food Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Food Name (e.g. Suya Chicken, Boiled Yam)',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter food name' : null,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _unitController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Serving Unit (e.g. 1 plate, 1 wrap, 150g)',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter serving unit' : null,
              ),

              const SizedBox(height: 20),

              // --- SCIENTIFIC MACRONUTRIENT INPUT SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Macronutrients', style: Theme.of(context).textTheme.titleLarge),
                  const Text(
                    'Per Serving',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Scientific Atwater Lock Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primaryOrange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Scientific Calorie Calculation',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryOrange),
                              ),
                              Text(
                                '${cals.round()} kcal',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryOrange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calories are strictly computed via the Atwater General Factor: (4 × Protein) + (4 × Carbs) + (9 × Fat). Manual calorie overrides are disabled to prevent unconscious under-reporting bias.',
                            style: TextStyle(fontSize: 11, height: 1.35, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _proteinController,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  prefixIcon: Icon(Icons.fitness_center_rounded, color: AppColors.accentGreen),
                  helperText: 'Provides 4 kcal per gram',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter protein amount (use 0 if none)' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _carbsController,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carbohydrates (g)',
                  prefixIcon: Icon(Icons.grain_rounded, color: AppColors.accentBlue),
                  helperText: 'Provides 4 kcal per gram',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter carbs amount (use 0 if none)' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _fatController,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  prefixIcon: Icon(Icons.opacity_rounded, color: AppColors.accentAmber),
                  helperText: 'Provides 9 kcal per gram',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter fat amount (use 0 if none)' : null,
              ),

              const SizedBox(height: 20),

              // Immediate Diary Logging Switch
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Log directly to today\'s food diary', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        value: _logImmediately,
                        onChanged: (val) => setState(() => _logImmediately = val),
                      ),
                      if (_logImmediately) ...[
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                            final isSel = _mealType == type;
                            return ChoiceChip(
                              label: Text(type),
                              selected: isSel,
                              selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setState(() => _mealType = type);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(_logImmediately ? 'Save & Log to Diary' : 'Save Custom Food'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveFood,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
