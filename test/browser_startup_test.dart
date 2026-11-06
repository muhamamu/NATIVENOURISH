import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:native_nourish/database/db_helper.dart';
import 'package:native_nourish/providers/food_provider.dart';
import 'package:native_nourish/providers/recipe_provider.dart';

void main() {
  test('browser database worker and WebAssembly runtime are packaged', () async {
    final wasm = await File('web/sqlite3.wasm').readAsBytes();
    expect(wasm.take(4), [0, 97, 115, 109]);
    expect(await File('web/sqflite_sw.js').length(), greaterThan(1000));
  });

  test('failed startup stops loading and retries load seeded foods and recipes', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final temp = await Directory.systemTemp.createTemp('native_nourish_startup_');
    final blockedPath = File.fromUri(temp.uri.resolve('unavailable'));
    await blockedPath.writeAsString('This file prevents creating a database directory.');
    await databaseFactory.setDatabasesPath(blockedPath.path);
    final food = FoodProvider();
    final recipes = RecipeProvider();
    Future<void> waitForLoads() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (food.isLoading || recipes.isLoading) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Loading did not finish');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    await waitForLoads();
    expect(food.loadError, isNotNull);
    expect(recipes.loadError, isNotNull);
    try {
      databaseFactory = databaseFactoryFfi;
      await databaseFactory.setDatabasesPath(temp.path);
      await Future.wait([food.loadInitialData(), recipes.loadRecipes()]);
      expect(food.loadError, isNull);
      expect(recipes.loadError, isNull);
      expect(food.allFoods.where((item) => item.category == 'Beverages'), isNotEmpty);
      expect(recipes.allRecipes, isNotEmpty);
    } finally {
      food.dispose();
      recipes.dispose();
      await (await DatabaseHelper.instance.database).close();
      await temp.delete(recursive: true);
    }
  });
}
