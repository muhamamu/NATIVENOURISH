import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:native_nourish/screens/profile_screen.dart';
import 'package:native_nourish/widgets/profile_avatar.dart';
import 'package:native_nourish/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter/services.dart';
import 'package:native_nourish/database/db_helper.dart';
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
import 'package:native_nourish/screens/food_search_screen.dart';
import 'package:native_nourish/screens/recipe_detail_screen.dart';

class TestPhotoPicker extends ImagePicker {
  final Uint8List bytes;
  TestPhotoPicker(this.bytes);
  @override
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth, double? maxHeight,
    int? imageQuality, CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true}) async => XFile.fromData(bytes, name: 'avatar.png', mimeType: 'image/png');
}

void main() {
  late Directory testDirectory;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Initialize FFI for SQLite database operations in test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDirectory = await Directory.systemTemp.createTemp('native_nourish_widgets_');
    await databaseFactory.setDatabasesPath(testDirectory.path);
    await DatabaseHelper.instance.database;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async => call.method == 'requestPermissions' ? <int, int>{} : 0);
  });

  tearDownAll(() async {
    await (await DatabaseHelper.instance.database).close();
    await testDirectory.delete(recursive: true);
  });

  Future<Widget> createTestApp(WidgetTester tester, Widget child) async {
    return (await tester.runAsync(() async {
      final theme = ThemeProvider();
      await theme.ready;
      final user = UserProvider();
      final food = FoodProvider();
      final activity = ActivityProvider();
      final recipes = RecipeProvider();
      final fasting = FastingProvider();
      final steps = StepTrackerService();
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (user.isLoading || food.isLoading || activity.isLoading || recipes.isLoading) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Providers did not finish loading');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await fasting.loadActiveFast();
      await steps.refreshDay();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => theme),
          ChangeNotifierProvider(create: (_) => user),
          ChangeNotifierProvider(create: (_) => food),
          ChangeNotifierProvider(create: (_) => activity),
          ChangeNotifierProvider(create: (_) => recipes),
          ChangeNotifierProvider(create: (_) => fasting),
          ChangeNotifierProvider(create: (_) => steps),
        ],
        child: MaterialApp(theme: ThemeData(), darkTheme: ThemeData.dark(), home: child),
      );
    }))!;
  }

  Future<void> waitForData(WidgetTester tester) async {
    // Decorative animations repeat forever, so use a bounded frame advance.
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('NativeNourish App renders dashboard and navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const MainNavigationScreen()));

    // Allow async providers to load initial data
    await waitForData(tester);

    // Verify app title & navigation tabs render properly
    expect(find.text('NativeNourish'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Food Log'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Settings screen renders units, dietary preference, and permissions', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const SettingsScreen()));
    await waitForData(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Measurement Units'), findsOneWidget);
    expect(find.text('Dietary Preferences'), findsOneWidget);
    expect(find.text('Smart Notifications'), findsOneWidget);
    expect(find.text('Hardware & Permissions'), findsOneWidget);
  });

  testWidgets('Appearance accent and brightness choices persist', (tester) async {
    await tester.pumpWidget(await createTestApp(tester, const SettingsScreen()));
    final context = tester.element(find.byType(SettingsScreen));
    final theme = context.read<ThemeProvider>();
    await tester.runAsync(() async {
      await tester.tap(find.text('Violet'));
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (await DatabaseHelper.instance.getSetting('accent') != 'Violet') {
        if (DateTime.now().isAfter(deadline)) throw StateError('Accent did not persist');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await theme.toggleTheme(false);
      final restored = ThemeProvider();
      await restored.ready;
      expect(restored.accentName, 'Violet');
      expect(restored.isDarkMode, isFalse);
      expect(AppColors.primaryAccent, AppColors.accentColors['Violet']);
      await theme.setAccent('Teal');
      restored.dispose();
    });
    await tester.pump();
    expect(find.text('App accent'), findsOneWidget);
  });

  testWidgets('Profile uploads a real photo, persists it, and can remove it', (tester) async {
    final bytes = await tester.runAsync(() => File('web/favicon.png').readAsBytes());
    await tester.pumpWidget(await createTestApp(tester, ProfileScreen(imagePicker: TestPhotoPicker(bytes!))));
    final context = tester.element(find.byType(ProfileScreen));
    final user = context.read<UserProvider>();
    await tester.tap(find.text('Change photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Upload photo'));
    for (var i = 0; i < 100 && !user.profile.profileImage.startsWith('data:image/'); i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(user.profile.profileImage, startsWith('data:image/'));
    await tester.runAsync(user.loadUserProfile);
    await tester.pump();
    expect(user.profile.profileImage, startsWith('data:image/'));
    expect(find.descendant(of: find.byType(ProfileAvatar), matching: find.byType(Image)), findsOneWidget);
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      if (tester.widget<TextButton>(find.widgetWithText(TextButton, 'Change photo')).onPressed != null) break;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Change photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Remove photo'));
    await tester.pump();
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while ((await DatabaseHelper.instance.getUserProfile()).profileImage.startsWith('data:image/')) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Photo removal did not persist');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump(const Duration(milliseconds: 400));
    expect(user.profile.profileImage, 'avatar_1');
  });

  testWidgets('Profile remains readable at phone width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await createTestApp(tester, const ProfileScreen()));
    await tester.pump();
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Maintain your current weight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Food Scanner renders camera viewfinder and capture controls', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const AiFoodScannerScreen()));
    await tester.pump();

    expect(find.text('Food Scanner Demo'), findsOneWidget);
    expect(find.textContaining('photos are not analyzed'), findsOneWidget);
    expect(find.text('Point Camera at Your Dish'), findsOneWidget);
    expect(find.text('Take Food Photo'), findsOneWidget);
  });

  testWidgets('Barcode Scanner renders viewfinder and staple shortcuts', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const BarcodeScannerScreen()));
    await tester.pump();

    expect(find.text('Barcode Scanner'), findsOneWidget);
    expect(find.text('Popular Packaged Staples:'), findsOneWidget);
    expect(find.text('Indomie Noodles'), findsOneWidget);
    expect(find.text('Peak Milk'), findsOneWidget);
  });

  testWidgets('Intermittent Fasting screen renders protocols and fasting clock', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const FastingScreen()));
    await waitForData(tester);

    expect(find.text('Intermittent Fasting'), findsOneWidget);
    expect(find.text('Select Fasting Protocol:'), findsOneWidget);
    expect(find.text('16:8 (Popular)'), findsOneWidget);
    expect(find.text('Metabolic Fasting Phases'), findsOneWidget);
  });

  testWidgets('Recipe Discovery screen renders search, categories, and recipes list', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const RecipeDiscoveryScreen()));
    await waitForData(tester);

    expect(find.text('Recipe Discovery'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Rice & Grains'), findsWidgets);
  });

  testWidgets('Food Log recipes ignore discovery filters and open recipe details', (tester) async {
    await tester.pumpWidget(await createTestApp(tester, const FoodSearchScreen()));
    final context = tester.element(find.byType(FoodSearchScreen));
    final recipes = context.read<RecipeProvider>();
    expect(recipes.allRecipes, isNotEmpty);
    final firstRecipe = recipes.allRecipes.first;
    recipes.selectCategory('No matching category');
    recipes.setNutrientFilters(minProtein: 9999);
    recipes.searchRecipes('no matching discovery query');
    expect(recipes.filteredRecipes, isEmpty);
    await tester.tap(find.text('Recipes 🍲'));
    await tester.pump();
    expect(find.text(firstRecipe.name), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'no matching food log query');
    await tester.pump();
    expect(find.text('No recipes found matching query'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '  Jollof  ');
    await tester.pump();
    expect(find.text(firstRecipe.name), findsOneWidget);
    expect(recipes.searchQuery, 'no matching discovery query');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text(firstRecipe.name));
    await tester.tap(find.text(firstRecipe.name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
  });

  testWidgets('Manual Food Entry screen renders preview and input fields', (WidgetTester tester) async {
    await tester.pumpWidget(await createTestApp(tester, const ManualFoodEntryScreen()));
    await waitForData(tester);

    expect(find.text('Manual Food Entry'), findsOneWidget);
    expect(find.text('NUTRITIONAL PREVIEW'), findsOneWidget);
    expect(find.text('Food Details'), findsOneWidget);
    expect(find.text('Macronutrients'), findsOneWidget);
  });

  testWidgets('Dashboard water starts at zero, adds, reduces, persists, and resets', (tester) async {
    await tester.pumpWidget(await createTestApp(tester, const MainNavigationScreen()));
    final context = tester.element(find.byType(MainNavigationScreen));
    final food = context.read<FoodProvider>();
    expect(food.todayWaterMl, 0);
    expect(find.text('0 ml'), findsOneWidget);
    expect(find.text('1,750 ml'), findsNothing);
    Future<void> tapWater(String label, double expected) async {
      final control = label == 'Reset Water' ? find.byTooltip(label) : find.text(label);
      await tester.ensureVisible(control);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() async {
        await tester.tap(control);
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (food.todayWaterMl != expected) {
          if (DateTime.now().isAfter(deadline)) throw StateError('Water update did not finish');
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      expect(food.todayWaterMl, expected);
    }
    expect(tester.getSize(find.byKey(const ValueKey('steps-card'))).height,
      tester.getSize(find.byKey(const ValueKey('water-card'))).height);
    await tapWater('+250 ml', 250);
    await tester.pump(const Duration(milliseconds: 150));
    final fill = tester.widget<LinearProgressIndicator>(find.descendant(
      of: find.byKey(const ValueKey('water-card')), matching: find.byType(LinearProgressIndicator)));
    expect(fill.value, greaterThan(0));
    expect(fill.value, lessThan(0.1));
    await tapWater('+500 ml', 750);
    await tester.runAsync(food.loadInitialData);
    await tester.pump();
    expect(food.todayWaterMl, 750);
    await tapWater('−250 ml', 500);
    await tapWater('Reset Water', 0);
    await tester.ensureVisible(find.text('Goal 2.5L'));
    await tester.tap(find.text('Goal 2.5L'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Save Goal'));
    await tester.pump();
    expect(find.text('Enter a positive amount in ml'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '3000');
    await tester.tap(find.text('Save Goal'));
    await tester.pump();
    await tester.runAsync(() async {
      final user = context.read<UserProvider>();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (user.profile.dailyWaterTargetMl != 3000 || user.isLoading) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Goal did not save');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await user.loadUserProfile();
      expect(user.profile.dailyWaterTargetMl, 3000);
    });
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Goal 3L'), findsOneWidget);
    final minus = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '−250 ml'));
    expect(minus.onPressed, isNull);
    await tester.runAsync(() async {
      await food.addWater(100);
      await food.reduceWater(250);
    });
    await tester.pump();
    expect(food.todayWaterMl, 0);
  });

  testWidgets('Reset All refreshes activity, recipes, fasting, and steps', (tester) async {
    await tester.pumpWidget(await createTestApp(tester, const SettingsScreen()));
    final context = tester.element(find.byType(SettingsScreen));
    final activities = context.read<ActivityProvider>();
    final recipes = context.read<RecipeProvider>();
    final fasting = context.read<FastingProvider>();
    final steps = context.read<StepTrackerService>();
    await tester.runAsync(() async {
      await activities.logActivity(activityName: 'Test workout', durationMinutes: 10, caloriesBurned: 50);
      await recipes.addCustomRecipe(Recipe(name: 'Reset regression dish', category: 'Main Dishes',
        prepTimeMinutes: 1, cookTimeMinutes: 1, defaultServings: 1,
        caloriesPerServing: 100, protein: 5, carbs: 10, fat: 4,
        ingredients: [], instructions: [], isCustom: true));
      await fasting.startFast();
      await steps.addManualSteps(100);
    });
    await tester.pump();
    expect(activities.todayActivityLogs, isNotEmpty);
    expect(recipes.allRecipes.any((r) => r.isCustom), isTrue);
    expect(fasting.isFasting, isTrue);
    expect(steps.todaySteps, 100);
    await tester.ensureVisible(find.text('Reset All User Data'));
    await tester.tap(find.text('Reset All User Data'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset All'));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (activities.todayActivityLogs.isNotEmpty ||
          recipes.allRecipes.any((r) => r.isCustom) || fasting.isFasting || steps.todaySteps != 0) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Reset did not refresh all providers');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump(const Duration(seconds: 2));
    expect(activities.todayBurnedCalories, 0);
    expect(recipes.allRecipes.any((r) => r.isCustom), isFalse);
    expect(fasting.startTime, isNull);
    expect(steps.todaySteps, 0);
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
