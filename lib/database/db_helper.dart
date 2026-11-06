import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/food.dart';
import '../models/meal_log.dart';
import '../models/user_profile.dart';
import '../models/activity_log.dart';
import '../models/recipe.dart';
import '../models/default_recipes.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _opening;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database?.isOpen ?? false) return _database!;
    return _opening ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      _database = await _initDB('native_nourish.db').timeout(const Duration(seconds: 20));
      return _database!;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = kIsWeb ? '' : await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        serving_unit TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        name TEXT,
        age INTEGER,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL,
        target_weight_kg REAL,
        activity_level TEXT,
        fitness_goal TEXT,
        profile_image TEXT,
        weight_unit TEXT,
        height_unit TEXT,
        dietary_preference TEXT,
        daily_water_target_ml REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER,
        food_name TEXT,
        meal_type TEXT,
        servings REAL,
        total_calories REAL,
        protein REAL,
        carbs REAL,
        fat REAL,
        logged_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_name TEXT,
        duration_minutes INTEGER,
        calories_burned REAL,
        steps_count INTEGER,
        logged_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        prep_time_minutes INTEGER,
        cook_time_minutes INTEGER,
        default_servings INTEGER,
        calories_per_serving REAL,
        protein REAL,
        carbs REAL,
        fat REAL,
        ingredients_json TEXT,
        instructions_json TEXT,
        image_url TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight_kg REAL NOT NULL,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml REAL NOT NULL,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fasting_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        target_hours INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS step_counts (
        date TEXT PRIMARY KEY,
        last_sensor INTEGER,
        sensor_steps INTEGER NOT NULL DEFAULT 0,
        manual_steps INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');

    // Pre-populate Default User Profile
    await db.insert('user_profile', {
      'id': 1,
      'name': 'NativeNourish User',
      'age': 26,
      'gender': 'male',
      'height_cm': 178.0,
      'weight_kg': 75.0,
      'target_weight_kg': 70.0,
      'activity_level': 'moderate',
      'fitness_goal': 'maintain',
      'profile_image': 'avatar_1',
      'weight_unit': 'kg',
      'height_unit': 'cm',
      'dietary_preference': 'West African Heritage',
      'daily_water_target_ml': 2500.0,
    });

    // Seed initial weight log
    await db.insert('weight_logs', {
      'weight_kg': 75.0,
      'logged_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first,
    });
    await db.insert('weight_logs', {
      'weight_kg': 74.5,
      'logged_at': DateTime.now().toIso8601String().split('T').first,
    });

    // Seed initial West African Food Composition dataset
    await _seedWestAfricanFoods(db);

    // Seed verified authentic recipes
    await _seedAuthenticRecipes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
    await db.execute('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    }
    if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS step_counts (
        date TEXT PRIMARY KEY,
        last_sensor INTEGER,
        sensor_steps INTEGER NOT NULL DEFAULT 0,
        manual_steps INTEGER NOT NULL DEFAULT 0
      )
    ''');
    }
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          prep_time_minutes INTEGER,
          cook_time_minutes INTEGER,
          default_servings INTEGER,
          calories_per_serving REAL,
          protein REAL,
          carbs REAL,
          fat REAL,
          ingredients_json TEXT,
          instructions_json TEXT,
          image_url TEXT,
          is_favorite INTEGER DEFAULT 0,
          is_custom INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS weight_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weight_kg REAL NOT NULL,
          logged_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount_ml REAL NOT NULL,
          logged_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS fasting_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time TEXT NOT NULL,
          end_time TEXT,
          target_hours INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');

      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN target_weight_kg REAL DEFAULT 70.0');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN profile_image TEXT DEFAULT 'avatar_1'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN weight_unit TEXT DEFAULT 'kg'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN height_unit TEXT DEFAULT 'cm'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN dietary_preference TEXT DEFAULT 'West African Heritage'");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN daily_water_target_ml REAL DEFAULT 2500.0');
      } catch (_) {}

      await _seedAuthenticRecipes(db);
    }
  }

  Future<void> _seedWestAfricanFoods(Database db) async {
    final List<Map<String, dynamic>> initialFoods = [
      {'name': 'Jollof Rice (Party Style)', 'category': 'Rice & Grains', 'serving_unit': '1 plate (300g)', 'calories': 480.0, 'protein': 9.5, 'carbs': 78.0, 'fat': 14.5, 'is_custom': 0},
      {'name': 'Egusi Soup (with Assorted Meat)', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 520.0, 'protein': 28.0, 'carbs': 12.0, 'fat': 40.0, 'is_custom': 0},
      {'name': 'Pounded Yam', 'category': 'Swallow / Tubers', 'serving_unit': '1 medium wrap (250g)', 'calories': 360.0, 'protein': 4.0, 'carbs': 84.0, 'fat': 0.8, 'is_custom': 0},
      {'name': 'Beef Suya Skewer', 'category': 'Proteins / Meats', 'serving_unit': '2 skewers (150g)', 'calories': 310.0, 'protein': 34.0, 'carbs': 6.0, 'fat': 16.5, 'is_custom': 0},
      {'name': 'Amala (Yam Flour Swallow)', 'category': 'Swallow / Tubers', 'serving_unit': '1 wrap (200g)', 'calories': 290.0, 'protein': 3.2, 'carbs': 68.0, 'fat': 0.6, 'is_custom': 0},
      {'name': 'Ewedu & Gbegiri Soup', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (200g)', 'calories': 180.0, 'protein': 10.0, 'carbs': 16.0, 'fat': 8.5, 'is_custom': 0},
      {'name': 'Fried Plantain (Dodo)', 'category': 'Sides & Snacks', 'serving_unit': '1 cup (150g)', 'calories': 320.0, 'protein': 2.0, 'carbs': 48.0, 'fat': 14.0, 'is_custom': 0},
      {'name': 'Boiled Plantain (Ripe/Unripe)', 'category': 'Sides & Snacks', 'serving_unit': '1 medium plantain (150g)', 'calories': 180.0, 'protein': 1.8, 'carbs': 45.0, 'fat': 0.5, 'is_custom': 0},
      {'name': 'Akara (Bean Cakes)', 'category': 'Breakfast / Snacks', 'serving_unit': '3 pieces (120g)', 'calories': 240.0, 'protein': 11.0, 'carbs': 26.0, 'fat': 10.0, 'is_custom': 0},
      {'name': 'Moi Moi (Steamed Bean Pudding)', 'category': 'Proteins / Legumes', 'serving_unit': '1 wrap (180g)', 'calories': 210.0, 'protein': 13.5, 'carbs': 28.0, 'fat': 5.5, 'is_custom': 0},
      {'name': 'Eba / Garri Swallow', 'category': 'Swallow / Tubers', 'serving_unit': '1 medium wrap (220g)', 'calories': 330.0, 'protein': 2.5, 'carbs': 78.0, 'fat': 0.9, 'is_custom': 0},
      {'name': 'Goat Meat Pepper Soup', 'category': 'Soups & Stews', 'serving_unit': '1 serving (300g)', 'calories': 260.0, 'protein': 32.0, 'carbs': 5.0, 'fat': 12.0, 'is_custom': 0},
      {'name': 'West African Fried Rice', 'category': 'Rice & Grains', 'serving_unit': '1 plate (300g)', 'calories': 460.0, 'protein': 11.0, 'carbs': 72.0, 'fat': 14.0, 'is_custom': 0},
      {'name': 'Ofada Rice & Ayamase Stew', 'category': 'Rice & Grains', 'serving_unit': '1 plate (320g)', 'calories': 560.0, 'protein': 22.0, 'carbs': 70.0, 'fat': 24.0, 'is_custom': 0},
      {'name': 'Waakye (Rice & Beans)', 'category': 'Rice & Grains', 'serving_unit': '1 plate (300g)', 'calories': 440.0, 'protein': 15.0, 'carbs': 76.0, 'fat': 8.0, 'is_custom': 0},
      {'name': 'Banku & Grilled Tilapia', 'category': 'Seafood & Meals', 'serving_unit': '1 portion (350g)', 'calories': 490.0, 'protein': 38.0, 'carbs': 52.0, 'fat': 13.0, 'is_custom': 0},
      {'name': 'Kenkey with Fish & Pepper', 'category': 'Meals', 'serving_unit': '1 ball with fish (300g)', 'calories': 420.0, 'protein': 26.0, 'carbs': 62.0, 'fat': 9.0, 'is_custom': 0},
      {'name': 'Okra Soup (with Fish)', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 220.0, 'protein': 24.0, 'carbs': 11.0, 'fat': 9.0, 'is_custom': 0},
      {'name': 'Ogbono Soup', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 450.0, 'protein': 20.0, 'carbs': 14.0, 'fat': 35.0, 'is_custom': 0},
      {'name': 'Banga Soup (Palm Fruit Soup)', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 510.0, 'protein': 22.0, 'carbs': 12.0, 'fat': 42.0, 'is_custom': 0},
      {'name': 'Afang Soup', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 380.0, 'protein': 26.0, 'carbs': 10.0, 'fat': 27.0, 'is_custom': 0},
      {'name': 'Edikaikong Soup', 'category': 'Soups & Stews', 'serving_unit': '1 bowl (250g)', 'calories': 360.0, 'protein': 28.0, 'carbs': 9.0, 'fat': 24.0, 'is_custom': 0},
      {'name': 'Nkwobi (Spiced Cow Foot)', 'category': 'Delicacies / Snacks', 'serving_unit': '1 serving (200g)', 'calories': 390.0, 'protein': 35.0, 'carbs': 4.0, 'fat': 26.0, 'is_custom': 0},
      {'name': 'Asun (Peppered Goat Meat)', 'category': 'Delicacies / Snacks', 'serving_unit': '1 portion (180g)', 'calories': 340.0, 'protein': 36.0, 'carbs': 3.0, 'fat': 20.0, 'is_custom': 0},
      {'name': 'Roasted Corn & Ube (African Pear)', 'category': 'Snacks', 'serving_unit': '1 cob + 2 pears', 'calories': 270.0, 'protein': 6.0, 'carbs': 42.0, 'fat': 10.0, 'is_custom': 0},
      {'name': 'Puff Puff', 'category': 'Snacks', 'serving_unit': '3 balls (100g)', 'calories': 310.0, 'protein': 4.5, 'carbs': 46.0, 'fat': 12.0, 'is_custom': 0},
      {'name': 'Zobo Drink (Unsweetened)', 'category': 'Beverages', 'serving_unit': '1 glass (300ml)', 'calories': 35.0, 'protein': 0.5, 'carbs': 8.0, 'fat': 0.1, 'is_custom': 0},
      {'name': 'Kunu (Millet Drink)', 'category': 'Beverages', 'serving_unit': '1 glass (300ml)', 'calories': 160.0, 'protein': 3.5, 'carbs': 32.0, 'fat': 1.5, 'is_custom': 0},
      {'name': 'Tuwo Shinkafa', 'category': 'Swallow / Tubers', 'serving_unit': '1 wrap (200g)', 'calories': 280.0, 'protein': 5.0, 'carbs': 62.0, 'fat': 0.6, 'is_custom': 0},
      {'name': 'Fufu (Cassava Swallow)', 'category': 'Swallow / Tubers', 'serving_unit': '1 wrap (220g)', 'calories': 310.0, 'protein': 1.8, 'carbs': 74.0, 'fat': 0.5, 'is_custom': 0},
    ];

    for (var food in initialFoods) {
      await db.insert('foods', food);
    }
  }

  Future<void> _seedAuthenticRecipes(Database db) async {
    // Check if recipes already exist
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count > 0) return;

    for (var recipe in DefaultRecipes.list) {
      await db.insert('recipes', recipe.toMap());
    }
  }

  // --- FOOD DAO CRUD ---
  Future<List<Food>> getAllFoods() async {
    final db = await instance.database;
    final maps = await db.query('foods', orderBy: 'name ASC');
    return maps.map((e) => Food.fromMap(e)).toList();
  }

  Future<List<Food>> searchFoods(String query) async {
    final db = await instance.database;
    final maps = await db.query(
      'foods',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((e) => Food.fromMap(e)).toList();
  }

  Future<int> insertFood(Food food) async {
    final db = await instance.database;
    return await db.insert('foods', food.toMap());
  }

  Future<int> deleteFood(int id) async {
    final db = await instance.database;
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  // --- MEAL LOG DAO CRUD ---
  Future<int> insertMealLog(MealLog log) async {
    final db = await instance.database;
    return await db.insert('meal_logs', log.toMap());
  }

  Future<List<MealLog>> getMealLogsByDate(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query('meal_logs', where: 'logged_at = ?', whereArgs: [dateStr]);
    return maps.map((e) => MealLog.fromMap(e)).toList();
  }

  Future<int> deleteMealLog(int id) async {
    final db = await instance.database;
    return await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearMealLogsByDate(String dateStr) async {
    final db = await instance.database;
    await db.delete('meal_logs', where: 'logged_at = ?', whereArgs: [dateStr]);
  }

  Future<void> clearAllMealLogs() async {
    final db = await instance.database;
    await db.delete('meal_logs');
  }

  // --- USER PROFILE DAO ---
  Future<UserProfile> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query('user_profile', where: 'id = 1');
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return UserProfile(
      name: 'NativeNourish User',
      age: 26,
      gender: 'male',
      heightCm: 178,
      weightKg: 75,
      targetWeightKg: 70,
      activityLevel: 'moderate',
      fitnessGoal: 'maintain',
      profileImage: 'avatar_1',
      weightUnit: 'kg',
      heightUnit: 'cm',
      dietaryPreference: 'West African Heritage',
      dailyWaterTargetMl: 2500,
    );
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await instance.database;
    await db.update('user_profile', profile.toMap(), where: 'id = 1');
  }

  // --- ACTIVITY LOG DAO ---
  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await instance.database;
    return await db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> getActivityLogsByDate(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query('activity_logs', where: 'logged_at = ?', whereArgs: [dateStr]);
    return maps.map((e) => ActivityLog.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getWeeklyCalorieSummary({DateTime? endDate}) async {
    final db = await instance.database;
    final end = endDate ?? DateTime.now();
    final days = List.generate(7, (index) => DateTime(end.year, end.month, end.day - 6 + index));
    String dateKey(DateTime date) => date.toIso8601String().split('T').first;
    final rows = await db.rawQuery('''
      SELECT logged_at as date, SUM(total_calories) as calories
      FROM meal_logs
      WHERE logged_at >= ? AND logged_at <= ?
      GROUP BY logged_at
    ''', [dateKey(days.first), dateKey(days.last)]);
    final totals = {for (final row in rows) row['date'] as String: row['calories']};
    return days.map((date) => <String, dynamic>{
      'date': dateKey(date),
      'calories': (totals[dateKey(date)] as num?)?.toDouble() ?? 0.0,
    }).toList();
  }

  // --- RECIPES DAO CRUD ---
  Future<List<Recipe>> getAllRecipes() async {
    final db = await instance.database;
    try {
      var maps = await db.query('recipes', orderBy: 'id ASC');
      if (maps.isEmpty) {
        await _seedAuthenticRecipes(db);
        maps = await db.query('recipes', orderBy: 'id ASC');
      }
      return maps.map((e) => Recipe.fromMap(e)).toList();
    } catch (_) {
      // Fallback: create table if missing and seed
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          prep_time_minutes INTEGER,
          cook_time_minutes INTEGER,
          default_servings INTEGER,
          calories_per_serving REAL,
          protein REAL,
          carbs REAL,
          fat REAL,
          ingredients_json TEXT,
          instructions_json TEXT,
          image_url TEXT,
          is_favorite INTEGER DEFAULT 0,
          is_custom INTEGER DEFAULT 0
        )
      ''');
      await _seedAuthenticRecipes(db);
      final maps = await db.query('recipes', orderBy: 'id ASC');
      return maps.map((e) => Recipe.fromMap(e)).toList();
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await instance.database;
    var maps = await db.query(
      'recipes',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    if (maps.isEmpty) {
      // Check if DB is unseeded
      final all = await getAllRecipes();
      if (all.isNotEmpty) {
        maps = await db.query(
          'recipes',
          where: 'name LIKE ? OR category LIKE ?',
          whereArgs: ['%$query%', '%$query%'],
          orderBy: 'name ASC',
        );
      }
    }
    return maps.map((e) => Recipe.fromMap(e)).toList();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await instance.database;
    final maps = await db.query('recipes', where: 'is_favorite = 1', orderBy: 'name ASC');
    return maps.map((e) => Recipe.fromMap(e)).toList();
  }

  Future<void> toggleFavoriteRecipe(int id, bool isFavorite) async {
    final db = await instance.database;
    await db.update(
      'recipes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // --- WEIGHT LOGS DAO ---
  Future<int> insertWeightLog(double weightKg, String dateStr) async {
    final db = await instance.database;
    return await db.insert('weight_logs', {
      'weight_kg': weightKg,
      'logged_at': dateStr,
    });
  }

  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    final db = await instance.database;
    return await db.query('weight_logs', orderBy: 'logged_at ASC', limit: 14);
  }

  // --- WATER LOGS DAO ---
  Future<int> insertWaterLog(double amountMl, String dateStr) async {
    final db = await instance.database;
    return await db.insert('water_logs', {
      'amount_ml': amountMl,
      'logged_at': dateStr,
    });
  }

  Future<double> getWaterTotalByDate(String dateStr) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT SUM(amount_ml) as total FROM water_logs WHERE logged_at = ?',
      [dateStr],
    );
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<void> reduceWaterLog(double amountMl, String dateStr) async {
    if (!amountMl.isFinite || amountMl <= 0) return;
    final db = await instance.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery('SELECT SUM(amount_ml) AS total FROM water_logs WHERE logged_at = ?', [dateStr]);
      final total = (rows.first['total'] as num?)?.toDouble() ?? 0.0;
      final reduction = amountMl.clamp(0.0, total < 0 ? 0.0 : total);
      if (reduction > 0) {
        await txn.insert('water_logs', {'amount_ml': -reduction, 'logged_at': dateStr});
      }
    });
  }

  Future<void> removeLastWaterEntry(String dateStr) async {
    final db = await instance.database;
    final lastRow = await db.query(
      'water_logs',
      where: 'logged_at = ?',
      whereArgs: [dateStr],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (lastRow.isNotEmpty) {
      final id = lastRow.first['id'] as int;
      await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> clearWaterLogsByDate(String dateStr) async {
    final db = await instance.database;
    await db.delete('water_logs', where: 'logged_at = ?', whereArgs: [dateStr]);
  }

  // --- FASTING DAO ---
  Future<Map<String, dynamic>?> getActiveFast() async {
    final db = await instance.database;
    final res = await db.query(
      'fasting_logs',
      where: 'is_active = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> startFast(DateTime startTime, int targetHours) async {
    final db = await instance.database;
    await db.update('fasting_logs', {'is_active': 0, 'end_time': DateTime.now().toIso8601String()}, where: 'is_active = 1');
    return await db.insert('fasting_logs', {
      'start_time': startTime.toIso8601String(),
      'end_time': null,
      'target_hours': targetHours,
      'is_active': 1,
    });
  }

  Future<void> endFast(DateTime endTime) async {
    final db = await instance.database;
    await db.update(
      'fasting_logs',
      {'is_active': 0, 'end_time': endTime.toIso8601String()},
      where: 'is_active = 1',
    );
  }

  Future<List<Map<String, dynamic>>> getFastingHistory() async {
    final db = await instance.database;
    return await db.query(
      'fasting_logs',
      where: 'is_active = 0',
      orderBy: 'id DESC',
      limit: 7,
    );
  }

  Future<Map<String, dynamic>?> getStepCounts(String date) async {
    final db = await instance.database;
    final rows = await db.query('step_counts', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveStepCounts(Map<String, dynamic> counts) async {
    final db = await instance.database;
    await db.insert('step_counts', counts, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('app_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- DATABASE RESET ---
  Future<void> resetToDefaults() async {
    final db = await instance.database;
    await db.delete('meal_logs');
    await db.delete('activity_logs');
    await db.delete('water_logs');
    await db.delete('fasting_logs');
    await db.delete('step_counts');
    await db.delete('foods', where: 'is_custom = 1');
    await db.delete('recipes', where: 'is_custom = 1');
  }
}
