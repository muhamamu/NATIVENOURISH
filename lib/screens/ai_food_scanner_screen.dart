import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/food_provider.dart';
import '../models/food.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/meal_success_overlay.dart';

enum ScanStep {
  initial,
  photoSelected,
  resultReady,
}

class DetectedFoodItem {
  String name;
  String category;
  double baseProtein;
  double baseCarbs;
  double baseFat;
  double servingMultiplier;
  String unit;

  DetectedFoodItem({
    required this.name,
    required this.category,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    this.servingMultiplier = 1.0,
    required this.unit,
    double? baseCalories,
  });

  /// Strict Atwater calculation: 4 kcal/g protein, 4 kcal/g carbs, 9 kcal/g fat
  double get baseCalories => (baseProtein * 4.0) + (baseCarbs * 4.0) + (baseFat * 9.0);
  double get calories => baseCalories * servingMultiplier;
  double get protein => baseProtein * servingMultiplier;
  double get carbs => baseCarbs * servingMultiplier;
  double get fat => baseFat * servingMultiplier;
}

class AiFoodScannerScreen extends StatefulWidget {
  const AiFoodScannerScreen({super.key});

  @override
  State<AiFoodScannerScreen> createState() => _AiFoodScannerScreenState();
}

class _AiFoodScannerScreenState extends State<AiFoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  ScanStep _currentStep = ScanStep.initial;


  DetectedFoodItem? _detectedItem;
  String _selectedMealType = 'Lunch';
  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _calCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();

  final List<DetectedFoodItem> _demoMeals = [
    DetectedFoodItem(
      name: 'Jollof Rice with Grilled Chicken',
      category: 'Rice & Grains',
      baseCalories: 510.0,
      baseProtein: 32.0,
      baseCarbs: 68.0,
      baseFat: 12.0,
      unit: '1 plate (320g)',
    ),
    DetectedFoodItem(
      name: 'Egusi Soup with Lean Meat',
      category: 'Soups & Stews',
      baseCalories: 480.0,
      baseProtein: 30.0,
      baseCarbs: 14.0,
      baseFat: 34.0,
      unit: '1 bowl (250g)',
    ),
    DetectedFoodItem(
      name: 'Beef Suya Skewer with Onions',
      category: 'Proteins / Meats',
      baseCalories: 310.0,
      baseProtein: 34.0,
      baseCarbs: 6.0,
      baseFat: 16.5,
      unit: '2 skewers (150g)',
    ),
    DetectedFoodItem(
      name: 'Fried Plantain (Dodo)',
      category: 'Sides & Snacks',
      baseCalories: 320.0,
      baseProtein: 2.0,
      baseCarbs: 48.0,
      baseFat: 14.0,
      unit: '1 cup (150g)',
    ),
    DetectedFoodItem(
      name: 'Moi Moi (Steamed Bean Pudding)',
      category: 'Proteins / Legumes',
      baseCalories: 210.0,
      baseProtein: 13.5,
      baseCarbs: 28.0,
      baseFat: 5.5,
      unit: '1 wrap (180g)',
    ),
    DetectedFoodItem(
      name: 'Grilled Whole Tilapia',
      category: 'Seafood & Meals',
      baseCalories: 340.0,
      baseProtein: 48.0,
      baseCarbs: 6.0,
      baseFat: 14.0,
      unit: '1 portion (300g)',
    ),
  ];

  @override
  void dispose() {
    _dishNameController.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (!kIsWeb && source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission is required. Please enable it in Settings.')),
            );
          }
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _currentStep = ScanStep.photoSelected;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _loadDemoExample() async {
    // This example is independent of the photo. No vision model is connected.
    final item = _demoMeals.first;
    _detectedItem = DetectedFoodItem(
      name: item.name,
      category: item.category,
      baseCalories: item.baseCalories,
      baseProtein: item.baseProtein,
      baseCarbs: item.baseCarbs,
      baseFat: item.baseFat,
      unit: item.unit,
      servingMultiplier: 1.0,
    );
    _dishNameController.text = _detectedItem!.name;
    _calCtrl.text = _detectedItem!.baseCalories.round().toString();
    _proteinCtrl.text = _detectedItem!.baseProtein.round().toString();
    _carbsCtrl.text = _detectedItem!.baseCarbs.round().toString();
    _fatCtrl.text = _detectedItem!.baseFat.round().toString();

    setState(() {
      _currentStep = ScanStep.resultReady;
    });
  }

  Future<void> _confirmAndSave() async {
    if (_detectedItem == null) return;

    final parsedCal = double.tryParse(_calCtrl.text) ?? _detectedItem!.baseCalories;
    final parsedProtein = double.tryParse(_proteinCtrl.text) ?? _detectedItem!.baseProtein;
    final parsedCarbs = double.tryParse(_carbsCtrl.text) ?? _detectedItem!.baseCarbs;
    final parsedFat = double.tryParse(_fatCtrl.text) ?? _detectedItem!.baseFat;

    final food = Food(
      name: _dishNameController.text.trim().isNotEmpty ? _dishNameController.text.trim() : _detectedItem!.name,
      category: _detectedItem!.category,
      servingUnit: _detectedItem!.unit,
      calories: parsedCal,
      protein: parsedProtein,
      carbs: parsedCarbs,
      fat: parsedFat,
      isCustom: true,
    );

    final servings = _detectedItem!.servingMultiplier;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    await foodProvider.logMeal(
      food: food,
      mealType: _selectedMealType,
      servings: servings,
    );

    if (!mounted) return;
    Navigator.pop(context);

    MealSuccessOverlay.show(
      context,
      title: food.name,
      mealType: _selectedMealType,
      calories: parsedCal * servings,
      protein: parsedProtein * servings,
      carbs: parsedCarbs * servings,
      fat: parsedFat * servings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner Demo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_currentStep == ScanStep.photoSelected || _currentStep == ScanStep.resultReady)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Retake Photo',
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _detectedItem = null;
                  _currentStep = ScanStep.initial;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Demo only — photos are not analyzed. The example meal is sample data; enter your actual meal details before saving.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_currentStep == ScanStep.initial) _buildInitialCameraView(isDark),
              if (_currentStep == ScanStep.photoSelected) _buildPreviewView(isDark),
              if (_currentStep == ScanStep.resultReady) _buildResultsView(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. INITIAL CAMERA VIEW ---
  Widget _buildInitialCameraView(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scanner Grid / Corner Reticles
              CustomPaint(
                size: const Size(260, 260),
                painter: _ViewfinderReticlePainter(color: AppColors.primaryAccent),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.primaryAccent, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Point Camera at Your Dish',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Position the plate within the frame for optimal portion & calorie detection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Capture Controls
        Row(
          children: [
            Expanded(
              child: BouncingButton(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryAccentDark, AppColors.primaryAccentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Take Food Photo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            BouncingButton(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Icon(Icons.photo_library_outlined, size: 24, color: AppColors.accentBlue),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. PHOTO PREVIEW VIEW ---
  Widget _buildPreviewView(bool isDark) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 340,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: _selectedImage != null
                ? (kIsWeb
                    ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                : const SizedBox(),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Retake'),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _currentStep = ScanStep.initial;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primaryAccentDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                label: const Text('Load Demo Example', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _loadDemoExample,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 4. RESULTS READY VIEW (EDITABLE BREAKDOWN) ---
  Widget _buildResultsView(bool isDark) {
    if (_detectedItem == null) return const SizedBox();
    final item = _detectedItem!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identified Food Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Demo Example', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('This sample was not detected from your photo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _dishNameController,
                decoration: const InputDecoration(
                  labelText: 'Example Dish Name',
                  prefixIcon: Icon(Icons.restaurant_rounded),
                ),
              ),

              const SizedBox(height: 16),

              // Portion Size Multiplier Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Portion Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    '${item.servingMultiplier.toStringAsFixed(1)}x serving (${item.unit})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
                  ),
                ],
              ),
              Slider(
                value: item.servingMultiplier,
                min: 0.5,
                max: 3.0,
                divisions: 5,
                label: '${item.servingMultiplier.toStringAsFixed(1)}x',
                onChanged: (val) {
                  setState(() {
                    item.servingMultiplier = val;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Estimated Nutrition Metrics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroMetric('${item.calories.round()}', 'kcal', AppColors.primaryAccent),
                    _buildMacroMetric('${item.protein.round()}g', 'Protein', AppColors.accentGreen),
                    _buildMacroMetric('${item.carbs.round()}g', 'Carbs', AppColors.accentBlue),
                    _buildMacroMetric('${item.fat.round()}g', 'Fat', AppColors.accentAmber),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text('Customize Nutritional Estimation (Full Control):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _calCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Calories (kcal)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)', isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbs (g)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fat (g)', isDense: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Meal Type Selector
              const Text('Log As:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                  final isSel = _selectedMealType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                    onSelected: (val) {
                      if (val) setState(() => _selectedMealType = type);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Scientific / AI Disclaimer Note (Explicit Requirement)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primaryAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo only: no image analysis is performed. This sample is unrelated to your photo. Replace the dish and nutrition with your own values before saving.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 1-Tap Save Action Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text(
              'Confirm & Save to Diary',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: _confirmAndSave,
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMacroMetric(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ViewfinderReticlePainter extends CustomPainter {
  final Color color;
  _ViewfinderReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
