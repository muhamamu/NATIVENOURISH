import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_theme.dart';

class RecipeBuilderScreen extends StatefulWidget {
  const RecipeBuilderScreen({super.key});

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController(text: '15');
  final TextEditingController _cookTimeController = TextEditingController(text: '25');
  final TextEditingController _servingsController = TextEditingController(text: '4');

  String _selectedCategory = 'Main Dishes';
  final List<String> _categories = [
    'Main Dishes',
    'Rice & Grains',
    'Soups & Stews',
    'Proteins / Meats',
    'Breakfast / Snacks',
    'Seafood & Meals',
  ];

  final List<RecipeIngredient> _ingredients = [];
  final List<String> _instructions = [];

  // Controllers for adding an ingredient (Calories are auto-calculated strictly from Atwater factor)
  final TextEditingController _ingNameCtrl = TextEditingController();
  final TextEditingController _ingAmountCtrl = TextEditingController(text: '100');
  final TextEditingController _ingUnitCtrl = TextEditingController(text: 'g');
  final TextEditingController _ingPCtrl = TextEditingController(text: '10');
  final TextEditingController _ingCCtrl = TextEditingController(text: '15');
  final TextEditingController _ingFCtrl = TextEditingController(text: '5');

  // Controller for adding a step
  final TextEditingController _stepCtrl = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _ingNameCtrl.dispose();
    _ingAmountCtrl.dispose();
    _ingUnitCtrl.dispose();
    _ingPCtrl.dispose();
    _ingCCtrl.dispose();
    _ingFCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  double get _totalCalories => _ingredients.fold(0.0, (s, i) => s + i.calories);
  double get _totalProtein => _ingredients.fold(0.0, (s, i) => s + i.protein);
  double get _totalCarbs => _ingredients.fold(0.0, (s, i) => s + i.carbs);
  double get _totalFat => _ingredients.fold(0.0, (s, i) => s + i.fat);

  int get _servingsCount => int.tryParse(_servingsController.text) ?? 1;

  double get _calsPerServing => _servingsCount > 0 ? _totalCalories / _servingsCount : 0.0;
  double get _proteinPerServing => _servingsCount > 0 ? _totalProtein / _servingsCount : 0.0;
  double get _carbsPerServing => _servingsCount > 0 ? _totalCarbs / _servingsCount : 0.0;
  double get _fatPerServing => _servingsCount > 0 ? _totalFat / _servingsCount : 0.0;

  void _showAddIngredientDialog() {
    _ingNameCtrl.clear();
    _ingAmountCtrl.text = '100';
    _ingUnitCtrl.text = 'g';
    _ingPCtrl.text = '8';
    _ingCCtrl.text = '12';
    _ingFCtrl.text = '4';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final p = double.tryParse(_ingPCtrl.text) ?? 0.0;
          final c = double.tryParse(_ingCCtrl.text) ?? 0.0;
          final f = double.tryParse(_ingFCtrl.text) ?? 0.0;
          final computedCals = (p * 4.0) + (c * 4.0) + (f * 9.0);

          return AlertDialog(
            title: const Text('Add Ingredient'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _ingNameCtrl,
                    decoration: const InputDecoration(labelText: 'Ingredient Name (e.g. Chicken breast, Egusi)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ingUnitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit (g, cups, tbsp)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Auto-calculated Atwater calories badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: AppColors.primaryOrange),
                            SizedBox(width: 6),
                            Text('Computed Calories:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${computedCals.round()} kcal',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ingPCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      prefixIcon: Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.accentGreen),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ingCCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Carbohydrates (g)',
                      prefixIcon: Icon(Icons.grain_rounded, size: 18, color: AppColors.accentBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ingFCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      prefixIcon: Icon(Icons.opacity_rounded, size: 18, color: AppColors.accentAmber),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                onPressed: () {
                  final name = _ingNameCtrl.text.trim();
                  if (name.isNotEmpty) {
                    final pVal = double.tryParse(_ingPCtrl.text) ?? 0.0;
                    final cVal = double.tryParse(_ingCCtrl.text) ?? 0.0;
                    final fVal = double.tryParse(_ingFCtrl.text) ?? 0.0;
                    final calsVal = (pVal * 4.0) + (cVal * 4.0) + (fVal * 9.0);

                    setState(() {
                      _ingredients.add(
                        RecipeIngredient(
                          name: name,
                          amount: double.tryParse(_ingAmountCtrl.text) ?? 100,
                          unit: _ingUnitCtrl.text.trim().isNotEmpty ? _ingUnitCtrl.text.trim() : 'g',
                          calories: calsVal,
                          protein: pVal,
                          carbs: cVal,
                          fat: fVal,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Ingredient', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddStepDialog() {
    _stepCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Cooking Step'),
        content: TextField(
          controller: _stepCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Describe preparation or cooking instruction...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            onPressed: () {
              final step = _stepCtrl.text.trim();
              if (step.isNotEmpty) {
                setState(() => _instructions.add(step));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Step', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveCustomRecipe() {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient to calculate nutrition.')),
      );
      return;
    }

    final recipe = Recipe(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 15,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 25,
      defaultServings: _servingsCount,
      caloriesPerServing: _calsPerServing,
      protein: _proteinPerServing,
      carbs: _carbsPerServing,
      fat: _fatPerServing,
      ingredients: List.from(_ingredients),
      instructions: _instructions.isNotEmpty ? List.from(_instructions) : ['Combine ingredients and cook thoroughly to taste.'],
      isCustom: true,
      isFavorite: true,
    );

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    recipeProvider.addCustomRecipe(recipe);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Custom recipe "${recipe.name}" saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Recipe Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              // --- NUTRITIONAL VALUE SUMMARY CARD ---
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
                        const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: AppColors.primaryOrange),
                            SizedBox(width: 4),
                            Text('ATWATER CERTIFIED NUTRITION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                          ],
                        ),
                        Text('$_servingsCount servings', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroBadge('${_calsPerServing.round()}', 'kcal/serv', AppColors.primaryOrange),
                        _buildMacroBadge('${_proteinPerServing.toStringAsFixed(1)}g', 'Protein', AppColors.accentGreen),
                        _buildMacroBadge('${_carbsPerServing.toStringAsFixed(1)}g', 'Carbs', AppColors.accentBlue),
                        _buildMacroBadge('${_fatPerServing.toStringAsFixed(1)}g', 'Fat', AppColors.accentAmber),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Recipe Energy:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${_totalCalories.round()} kcal total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text('Recipe Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Title (e.g. Grandma\'s Fisherman Soup)',
                  prefixIcon: Icon(Icons.restaurant_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter recipe title' : null,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prep Time (min)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cook Time (min)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Servings'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- INGREDIENTS LIST & ADD BUTTON ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ingredients (${_ingredients.length})', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Ingredient'),
                    onPressed: _showAddIngredientDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_ingredients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: const Center(
                    child: Text('No ingredients added yet. Tap "Add Ingredient" above.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = _ingredients[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 12)),
                        ),
                        title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${ing.amount.round()} ${ing.unit} • ${ing.calories.round()} kcal (P: ${ing.protein}g, C: ${ing.carbs}g, F: ${ing.fat}g)',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() => _ingredients.removeAt(index));
                          },
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // --- INSTRUCTIONS SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cooking Steps (${_instructions.length})', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Step'),
                    onPressed: _showAddStepDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_instructions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: const Center(
                    child: Text('No cooking steps added yet. Tap "Add Step" above.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _instructions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentBlue, fontSize: 12)),
                        ),
                        title: Text(_instructions[index], style: const TextStyle(fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() => _instructions.removeAt(index));
                          },
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Custom Recipe'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _saveCustomRecipe,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
