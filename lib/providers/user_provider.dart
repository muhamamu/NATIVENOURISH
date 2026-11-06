import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/user_profile.dart';
import '../services/bmr_calculator.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = UserProfile(
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

  List<Map<String, dynamic>> _weightHistory = [];
  bool _isLoading = true;

  UserProfile get profile => _profile;
  List<Map<String, dynamic>> get weightHistory => _weightHistory;
  bool get isLoading => _isLoading;

  double get bmr => BmrCalculator.calculateBMR(_profile);
  double get tdee => BmrCalculator.calculateTDEE(_profile);
  double get dailyCalorieTarget => BmrCalculator.calculateDailyTargetCalories(_profile);
  double get targetProtein => BmrCalculator.calculateTargetProtein(dailyCalorieTarget, _profile.dietaryPreference);
  double get targetCarbs => BmrCalculator.calculateTargetCarbs(dailyCalorieTarget, _profile.dietaryPreference);
  double get targetFat => BmrCalculator.calculateTargetFat(dailyCalorieTarget, _profile.dietaryPreference);

  UserProvider() {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    _profile = await DatabaseHelper.instance.getUserProfile();
    _weightHistory = await DatabaseHelper.instance.getWeightHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    await DatabaseHelper.instance.updateUserProfile(newProfile);
    await loadUserProfile();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> logWeight(double weightKg) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await DatabaseHelper.instance.insertWeightLog(weightKg, todayStr);
    _profile = _profile.copyWith(weightKg: weightKg);
    await DatabaseHelper.instance.updateUserProfile(_profile);
    _weightHistory = await DatabaseHelper.instance.getWeightHistory();
    notifyListeners();
  }
}
