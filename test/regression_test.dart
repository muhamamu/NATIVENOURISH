import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:native_nourish/database/db_helper.dart';
import 'package:native_nourish/models/user_profile.dart';
import 'package:native_nourish/services/step_tracker_service.dart';

void main() {
  late Directory temp;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('native_nourish_regression_');
    await databaseFactory.setDatabasesPath(temp.path);
    final db = await databaseFactory.openDatabase(path.join(temp.path, 'native_nourish.db'),
      options: OpenDatabaseOptions(version: 2, onCreate: (db, _) async {
        await db.execute('CREATE TABLE meal_logs (logged_at TEXT, total_calories REAL)');
      }));
    await db.close();
  });
  tearDownAll(() async {
    await (await DatabaseHelper.instance.database).close();
    await temp.delete(recursive: true);
  });
  test('pounds display and input preserve kilograms', () {
    final profile = UserProfile(name: 'Test', age: 30, gender: 'male',
      heightCm: 180, weightKg: 75, targetWeightKg: 70,
      activityLevel: 'moderate', fitnessGoal: 'maintain', weightUnit: 'lbs');
    expect(profile.displayWeight, closeTo(165.3467, 0.001));
    expect(profile.displayTargetWeight, closeTo(154.3236, 0.001));
    expect(profile.weightInputToKg(profile.displayWeight), closeTo(75, 0.00001));
    expect(profile.weightInputToKg(165), closeTo(74.8427, 0.001));
    expect(profile.copyWith(weightUnit: 'kg').weightInputToKg(75), 75);
  });
  test('weekly totals include seven calendar days and exclude older records', () async {
    final db = await DatabaseHelper.instance.database;
    for (final row in [
      {'logged_at': '2026-10-30', 'total_calories': 9999},
      {'logged_at': '2026-10-31', 'total_calories': 100},
      {'logged_at': '2026-11-06', 'total_calories': 200},
      {'logged_at': '2026-11-06', 'total_calories': 300},
      {'logged_at': '2026-11-07', 'total_calories': 9999},
    ]) { await db.insert('meal_logs', row); }
    final days = await DatabaseHelper.instance.getWeeklyCalorieSummary(endDate: DateTime(2026, 11, 6));
    expect(days.length, 7);
    expect(days.first, {'date': '2026-10-31', 'calories': 100.0});
    expect(days[1]['calories'], 0.0);
    expect(days.last, {'date': '2026-11-06', 'calories': 500.0});
  });
  test('version-2 databases gain persistent daily step storage', () async {
    await DatabaseHelper.instance.saveStepCounts({
      'date': '2026-11-06', 'last_sensor': 1000, 'sensor_steps': 20, 'manual_steps': 30,
    });
    final saved = await DatabaseHelper.instance.getStepCounts('2026-11-06');
    expect(saved?['sensor_steps'], 20);
    expect(saved?['manual_steps'], 30);
  });
  test('steps survive restart, preserve manual additions, and reset daily', () async {
    var now = DateTime(2026, 11, 6, 12);
    final store = <String, Map<String, dynamic>>{};
    StepTrackerService create() => StepTrackerService(now: () => now,
      readCounts: (date) async => store[date],
      writeCounts: (counts) async { store[counts['date'] as String] = Map.of(counts); });
    var service = create();
    await service.refreshDay();
    expect(service.todaySteps, 0);
    await service.recordSensorSteps(1000);
    await service.recordSensorSteps(1100);
    await service.addManualSteps(1000);
    await service.recordSensorSteps(1150);
    expect(service.todaySteps, 1150);
    service.dispose();
    service = create();
    await service.recordSensorSteps(1200);
    expect(service.todaySteps, 1200);
    await service.recordSensorSteps(10);
    expect(service.todaySteps, 1210);
    now = DateTime(2026, 11, 7);
    await service.refreshDay();
    expect(service.todaySteps, 0);
    await service.recordSensorSteps(20);
    await service.recordSensorSteps(40);
    expect(service.todaySteps, 20);
    await service.resetCounts();
    expect(service.todaySteps, 0);
    await service.recordSensorSteps(50);
    expect(service.todaySteps, 10);
    service.dispose();
  });
}
