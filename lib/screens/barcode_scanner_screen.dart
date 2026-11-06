import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/open_food_facts_service.dart';
import '../models/food.dart';
import '../providers/food_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/meal_success_overlay.dart';
import '../widgets/skeleton_loader.dart';
import 'manual_food_entry_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _barcodeInputController = TextEditingController();
  late AnimationController _laserAnimCtrl;
  late Animation<double> _laserAnim;

  bool _isSearching = false;
  Food? _foundProduct;
  double _servings = 1.0;
  String _mealType = 'Lunch';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _laserAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _laserAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserAnimCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimCtrl.dispose();
    _barcodeInputController.dispose();
    super.dispose();
  }

  Future<void> _searchBarcode([String? code]) async {
    final query = code ?? _barcodeInputController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundProduct = null;
    });

    final product = await OpenFoodFactsService.lookupBarcode(query);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      if (product != null) {
        _foundProduct = product;
      } else {
        _errorMessage = 'No packaged item found for barcode "$query". Try entering nutrition manually.';
      }
    });
  }

  void _logProduct() {
    if (_foundProduct == null) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.logMeal(
      food: _foundProduct!,
      mealType: _mealType,
      servings: _servings,
    );

    Navigator.pop(context);

    MealSuccessOverlay.show(
      context,
      title: _foundProduct!.name,
      mealType: _mealType,
      calories: _foundProduct!.calories * _servings,
      protein: _foundProduct!.protein * _servings,
      carbs: _foundProduct!.carbs * _servings,
      fat: _foundProduct!.fat * _servings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner Viewfinder Card
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.black87,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 140),
                    painter: _BarcodeReticlePainter(color: AppColors.primaryOrange),
                  ),
                  AnimatedBuilder(
                    animation: _laserAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: 220 * _laserAnim.value,
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, AppColors.primaryOrange, Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Align barcode within frame',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Barcode Manual Entry & Quick Scan
            TextField(
              controller: _barcodeInputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter UPC/EAN barcode (e.g. 8992388111013)',
                prefixIcon: const Icon(Icons.barcode_reader, color: AppColors.primaryOrange),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.primaryOrange),
                  onPressed: () => _searchBarcode(),
                ),
              ),
              onSubmitted: (val) => _searchBarcode(val),
            ),

            const SizedBox(height: 12),

            // Quick Samples chips
            const Text('Popular Packaged Staples:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickBarcodeChip('Indomie Noodles', '8992388111013'),
                _buildQuickBarcodeChip('Peak Milk', '8712800010018'),
                _buildQuickBarcodeChip('Milo Drink', '7613035987654'),
                _buildQuickBarcodeChip('Titus Sardines', '034100573062'),
                _buildQuickBarcodeChip('Golden Penny Semo', '6151100000012'),
              ],
            ),

            const SizedBox(height: 20),

            if (_isSearching) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange)),
                      SizedBox(height: 12),
                      Text('Querying OpenFoodFacts Database...', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 12),
                      SkeletonLoader(width: double.infinity, height: 16),
                    ],
                  ),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add as Custom Food Item'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManualFoodEntryScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_foundProduct != null) ...[
              Container(
                width: double.infinity,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundProduct!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _foundProduct!.servingUnit,
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Portions slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Servings', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_servings.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      ],
                    ),
                    Slider(
                      value: _servings,
                      min: 0.5,
                      max: 4.0,
                      divisions: 7,
                      label: '${_servings.toStringAsFixed(1)}x',
                      onChanged: (v) => setState(() => _servings = v),
                    ),

                    const SizedBox(height: 12),

                    // Nutrient row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientBadge('${(_foundProduct!.calories * _servings).round()}', 'kcal', AppColors.primaryOrange),
                          _buildNutrientBadge('${(_foundProduct!.protein * _servings).round()}g', 'Protein', AppColors.accentGreen),
                          _buildNutrientBadge('${(_foundProduct!.carbs * _servings).round()}g', 'Carbs', AppColors.accentBlue),
                          _buildNutrientBadge('${(_foundProduct!.fat * _servings).round()}g', 'Fat', AppColors.accentAmber),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Meal type selector
                    const Text('Select Meal Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.check_rounded, color: Colors.white),
                        label: const Text('Log Product to Diary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _logProduct,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBarcodeChip(String label, String code) {
    return BouncingButton(
      onTap: () {
        _barcodeInputController.text = code;
        _searchBarcode(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.primaryOrange),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _BarcodeReticlePainter extends CustomPainter {
  final Color color;
  _BarcodeReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;

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
