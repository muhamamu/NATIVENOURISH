import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/activity_log.dart';

class ActivityProvider extends ChangeNotifier {
  List<ActivityLog> _todayActivityLogs = [];
  List<Map<String, dynamic>> _weeklySummary = [];
  bool _isLoading = false;

  List<ActivityLog> get todayActivityLogs => _todayActivityLogs;
  List<Map<String, dynamic>> get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;

  String get _todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  double get todayBurnedCalories => _todayActivityLogs.fold(0.0, (sum, item) => sum + item.caloriesBurned);

  ActivityProvider() {
    loadTodayActivities();
  }

  Future<void> loadTodayActivities() async {
    _isLoading = true;
    notifyListeners();
    _todayActivityLogs = await DatabaseHelper.instance.getActivityLogsByDate(_todayDateStr);
    _weeklySummary = await DatabaseHelper.instance.getWeeklyCalorieSummary();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logActivity({
    required String activityName,
    required int durationMinutes,
    required double caloriesBurned,
    int stepsCount = 0,
  }) async {
    final log = ActivityLog(
      activityName: activityName,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      stepsCount: stepsCount,
      loggedAt: _todayDateStr,
    );

    await DatabaseHelper.instance.insertActivityLog(log);
    await loadTodayActivities();
  }
}
