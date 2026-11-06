import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:native_nourish/theme/app_theme.dart';
import 'package:native_nourish/providers/theme_provider.dart';
import 'package:native_nourish/providers/user_provider.dart';
import 'package:native_nourish/providers/food_provider.dart';
import 'package:native_nourish/providers/activity_provider.dart';
import 'package:native_nourish/providers/recipe_provider.dart';
import 'package:native_nourish/providers/fasting_provider.dart';
import 'package:native_nourish/services/step_tracker_service.dart';
import 'package:native_nourish/services/bmr_calculator.dart';
import 'package:native_nourish/services/open_food_facts_service.dart';
import 'package:native_nourish/models/user_profile.dart';
import 'package:native_nourish/models/recipe.dart';
import 'package:native_nourish/screens/main_navigation_screen.dart';
import 'package:native_nourish/screens/settings_screen.dart';
import 'package:native_nourish/screens/ai_food_scanner_screen.dart';
import 'package:native_nourish/screens/barcode_scanner_screen.dart';
import 'package:native_nourish/screens/fasting_screen.dart';
import 'package:native_nourish/screens/recipe_discovery_screen.dart';
import 'package:native_nourish/screens/manual_food_entry_screen.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for SQLite database operations in test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget createTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => FastingProvider()),
        ChangeNotifierProvider(create: (_) => StepTrackerService()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  testWidgets('NativeNourish App renders dashboard and navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const MainNavigationScreen()));

    // Allow async providers to load initial data
    await tester.pumpAndSettle();

    // Verify app title & navigation tabs render properly
    expect(find.text('NativeNourish'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Food Log'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Settings screen renders units, dietary preference, and permissions', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Measurement Units'), findsOneWidget);
    expect(find.text('Dietary Preferences'), findsOneWidget);
    expect(find.text('Smart Notifications'), findsOneWidget);
    expect(find.text('Hardware & Permissions'), findsOneWidget);
  });

  testWidgets('AI Food Scanner renders camera viewfinder and capture controls', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const AiFoodScannerScreen()));
    await tester.pump();

    expect(find.text('AI Food Scanner'), findsOneWidget);
    expect(find.text('Point Camera at Your Dish'), findsOneWidget);
    expect(find.text('Take Food Photo'), findsOneWidget);
  });

  testWidgets('Barcode Scanner renders viewfinder and staple shortcuts', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const BarcodeScannerScreen()));
    await tester.pump();

    expect(find.text('Barcode Scanner'), findsOneWidget);
    expect(find.text('Popular Packaged Staples:'), findsOneWidget);
    expect(find.text('Indomie Noodles'), findsOneWidget);
    expect(find.text('Peak Milk'), findsOneWidget);
  });

  testWidgets('Intermittent Fasting screen renders protocols and fasting clock', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const FastingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Intermittent Fasting'), findsOneWidget);
    expect(find.text('Select Fasting Protocol:'), findsOneWidget);
    expect(find.text('16:8 (Popular)'), findsOneWidget);
    expect(find.text('Metabolic Fasting Phases'), findsOneWidget);
  });

  testWidgets('Recipe Discovery screen renders search, categories, and recipes list', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const RecipeDiscoveryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Recipe Discovery'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Rice & Grains'), findsWidgets);
  });

  testWidgets('Manual Food Entry screen renders preview and input fields', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(const ManualFoodEntryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Manual Food Entry'), findsOneWidget);
    expect(find.text('NUTRITIONAL PREVIEW'), findsOneWidget);
    expect(find.text('Food Details'), findsOneWidget);
    expect(find.text('Macronutrients'), findsOneWidget);
  });

  test('OpenFoodFactsService offline catalog lookup returns authentic packaged goods', () async {
    final indomie = await OpenFoodFactsService.lookupBarcode('8992388111013');
    expect(indomie, isNotNull);
    expect(indomie!.name.contains('Indomie'), isTrue);
    expect(indomie.calories, 340.0);
    expect(indomie.protein, 8.0);

    final peakMilk = await OpenFoodFactsService.lookupBarcode('8712800010018');
    expect(peakMilk, isNotNull);
    expect(peakMilk!.name.contains('Peak'), isTrue);
  });

  test('BMR & TDEE Calculations with Mifflin-St Jeor equation and macro splits', () {
    final profile = UserProfile(
      name: 'Test Athlete',
      age: 25,
      gender: 'male',
      heightCm: 180,
      weightKg: 80,
      targetWeightKg: 75,
      activityLevel: 'moderate',
      fitnessGoal: 'lose',
      dietaryPreference: 'High Protein',
    );

    final bmr = BmrCalculator.calculateBMR(profile);
    expect(bmr, 1805.0);

    final tdee = BmrCalculator.calculateTDEE(profile);
    expect(tdee, 1805.0 * 1.55);

    final targetCals = BmrCalculator.calculateDailyTargetCalories(profile);
    expect(targetCals, tdee - 500);

    final proteinGrams = BmrCalculator.calculateTargetProtein(targetCals, 'High Protein');
    expect(proteinGrams, (targetCals * 0.35) / 4.0);

    expect(profile.bmi, closeTo(80 / (1.8 * 1.8), 0.1));
    expect(profile.bmiCategory, 'Healthy Weight');
  });

  test('Recipe model serializes and deserializes correctly with ingredients and instructions', () {
    final recipe = Recipe(
      id: 99,
      name: 'Spicy Suya Beef',
      category: 'Proteins / Meats',
      prepTimeMinutes: 15,
      cookTimeMinutes: 10,
      defaultServings: 2,
      caloriesPerServing: 350,
      protein: 40,
      carbs: 5,
      fat: 15,
      ingredients: [
        RecipeIngredient(name: 'Beef Strips', amount: 300, unit: 'g', calories: 450, protein: 60, carbs: 0, fat: 20),
      ],
      instructions: ['Thread onto skewers', 'Grill over hot coals'],
      isFavorite: true,
      isCustom: true,
    );

    final map = recipe.toMap();
    final restored = Recipe.fromMap(map);

    expect(restored.name, 'Spicy Suya Beef');
    expect(restored.ingredients.length, 1);
    expect(restored.ingredients.first.name, 'Beef Strips');
    expect(restored.instructions.length, 2);
    expect(restored.isFavorite, true);
    expect(restored.isCustom, true);
  });
}
