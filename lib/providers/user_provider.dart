import 'package:flutter/material.dart';
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
    activityLevel: 'moderate',
    fitnessGoal: 'maintain',
  );

  bool _isLoading = true;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;

  double get bmr => BmrCalculator.calculateBMR(_profile);
  double get tdee => BmrCalculator.calculateTDEE(_profile);
  double get dailyCalorieTarget => BmrCalculator.calculateDailyTargetCalories(_profile);
  double get targetProtein => BmrCalculator.calculateTargetProtein(dailyCalorieTarget);
  double get targetCarbs => BmrCalculator.calculateTargetCarbs(dailyCalorieTarget);
  double get targetFat => BmrCalculator.calculateTargetFat(dailyCalorieTarget);

  UserProvider() {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    _profile = await DatabaseHelper.instance.getUserProfile();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    _profile = newProfile;
    notifyListeners();
    await DatabaseHelper.instance.updateUserProfile(newProfile);
  }
}
