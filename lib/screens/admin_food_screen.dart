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
  final TextEditingController _caloriesController = TextEditingController();
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.darkGreenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add custom West African foods and nutritional composition data to the SQLite database.',
                      style: TextStyle(fontSize: 12),
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
                      const Text('Add New Dish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Dish Name (e.g., Kilishi, Banga Soup)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter dish name' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
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
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _caloriesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Protein (g)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Carbs (g)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _fatController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Fat (g)'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final newFood = Food(
                                name: _nameController.text.trim(),
                                category: _selectedCategory,
                                servingUnit: _unitController.text.trim(),
                                calories: double.tryParse(_caloriesController.text) ?? 0.0,
                                protein: double.tryParse(_proteinController.text) ?? 0.0,
                                carbs: double.tryParse(_carbsController.text) ?? 0.0,
                                fat: double.tryParse(_fatController.text) ?? 0.0,
                                isCustom: true,
                              );

                              foodProvider.addCustomFood(newFood);

                              _nameController.clear();
                              _caloriesController.clear();
                              _proteinController.clear();
                              _carbsController.clear();
                              _fatController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Custom West African dish saved to database!')),
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
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No custom admin dishes added yet.')),
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
                          title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${food.category} • ${food.calories.round()} kcal'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              if (food.id != null) foodProvider.deleteCustomFood(food.id!);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
