import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food.dart';

class OpenFoodFactsService {
  static final Map<String, Food> _localBarcodeDatabase = {
    '8992388111013': Food(
      name: 'Indomie Instant Noodles (Onion Chicken)',
      category: 'Rice & Grains',
      servingUnit: '1 pack (70g)',
      calories: 340.0,
      protein: 8.0,
      carbs: 44.0,
      fat: 14.0,
      isCustom: false,
    ),
    '8712800010018': Food(
      name: 'Peak Evaporated Milk',
      category: 'Beverages',
      servingUnit: '1 tin (160ml)',
      calories: 160.0,
      protein: 8.2,
      carbs: 11.5,
      fat: 9.0,
      isCustom: false,
    ),
    '7613035987654': Food(
      name: 'Milo Chocolate Malt Powder',
      category: 'Beverages',
      servingUnit: '3 tablespoons (30g)',
      calories: 124.0,
      protein: 3.5,
      carbs: 21.0,
      fat: 2.8,
      isCustom: false,
    ),
    '072310001020': Food(
      name: 'Quaker Whole Grain Rolled Oats',
      category: 'Rice & Grains',
      servingUnit: '1/2 cup dry (40g)',
      calories: 150.0,
      protein: 5.0,
      carbs: 27.0,
      fat: 3.0,
      isCustom: false,
    ),
    '034100573062': Food(
      name: 'Titus Wild Sardines in Pure Vegetable Oil',
      category: 'Proteins / Meats',
      servingUnit: '1 can drained (90g)',
      calories: 195.0,
      protein: 22.0,
      carbs: 0.0,
      fat: 11.5,
      isCustom: false,
    ),
    '6151100000012': Food(
      name: 'Golden Penny Semovita Swallow',
      category: 'Swallow / Tubers',
      servingUnit: '1 serving (100g dry)',
      calories: 358.0,
      protein: 11.5,
      carbs: 73.0,
      fat: 1.5,
      isCustom: false,
    ),
    '5701092100014': Food(
      name: 'Dano Full Cream Milk Powder',
      category: 'Beverages',
      servingUnit: '3 tablespoons (32g)',
      calories: 160.0,
      protein: 7.8,
      carbs: 12.0,
      fat: 8.5,
      isCustom: false,
    ),
  };

  static Map<String, Food> get offlineSamples => _localBarcodeDatabase;

  /// Helper to parse gram/ml quantity from OpenFoodFacts serving_size string (e.g. "30g" -> 30.0)
  static double _parseServingWeight(String servingSizeStr) {
    final regExp = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|ml|gram)');
    final match = regExp.firstMatch(servingSizeStr.toLowerCase());
    if (match != null && match.group(1) != null) {
      return double.tryParse(match.group(1)!) ?? 100.0;
    }
    return 100.0;
  }

  static Future<Food?> lookupBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return null;

    // Check offline dictionary first
    if (_localBarcodeDatabase.containsKey(cleanCode)) {
      return _localBarcodeDatabase[cleanCode];
    }

    // Query OpenFoodFacts API v2
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$cleanCode.json?fields=code,product_name,brands,nutriments,serving_size',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'NativeNourish/1.0 (support@nativenourish.app)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] != null) {
          final prod = data['product'] as Map<String, dynamic>;
          final name = prod['product_name'] as String? ?? 'Scanned Food Product';
          final brand = prod['brands'] as String? ?? '';
          final serving = prod['serving_size'] as String? ?? '1 portion (100g)';

          final nutriments = prod['nutriments'] as Map<String, dynamic>? ?? {};

          // Intelligent Serving Size Normalization
          double calories = 0.0;
          double protein = 0.0;
          double carbs = 0.0;
          double fat = 0.0;

          if (nutriments.containsKey('energy-kcal_serving')) {
            calories = (nutriments['energy-kcal_serving'] ?? 200.0).toDouble();
            protein = (nutriments['proteins_serving'] ?? 8.0).toDouble();
            carbs = (nutriments['carbohydrates_serving'] ?? 25.0).toDouble();
            fat = (nutriments['fat_serving'] ?? 6.0).toDouble();
          } else {
            // Fallback to 100g values scaled by parsed serving size weight
            final weightGram = _parseServingWeight(serving);
            final scale = weightGram / 100.0;
            calories = ((nutriments['energy-kcal_100g'] ?? 200.0) as num).toDouble() * scale;
            protein = ((nutriments['proteins_100g'] ?? 8.0) as num).toDouble() * scale;
            carbs = ((nutriments['carbohydrates_100g'] ?? 25.0) as num).toDouble() * scale;
            fat = ((nutriments['fat_100g'] ?? 6.0) as num).toDouble() * scale;
          }

          return Food(
            name: brand.isNotEmpty ? '$brand - $name' : name,
            category: 'Packaged Foods',
            servingUnit: serving,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            isCustom: true,
          );
        }
      }
    } catch (_) {
      // Graceful fallback
    }

    return null;
  }
}
