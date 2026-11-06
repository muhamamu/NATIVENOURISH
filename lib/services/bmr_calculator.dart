import '../models/user_profile.dart';

class BmrCalculator {
  /// Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double calculateBMR(UserProfile profile) {
    if (profile.gender.toLowerCase() == 'female') {
      return (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) - 161;
    } else {
      return (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) + 5;
    }
  }

  /// Activity Multiplier based on user activity level
  static double getActivityMultiplier(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
      case 'very active':
        return 1.725;
      default:
        return 1.55;
    }
  }

  /// Total Daily Energy Expenditure (TDEE)
  static double calculateTDEE(UserProfile profile) {
    final bmr = calculateBMR(profile);
    final multiplier = getActivityMultiplier(profile.activityLevel);
    return bmr * multiplier;
  }

  /// Recommended Daily Calorie Target based on fitness goal
  static double calculateDailyTargetCalories(UserProfile profile) {
    final tdee = calculateTDEE(profile);
    switch (profile.fitnessGoal.toLowerCase()) {
      case 'lose':
      case 'weight loss':
        return (tdee - 500).clamp(1200.0, 4500.0);
      case 'gain':
      case 'weight gain':
        return tdee + 500;
      case 'maintain':
      default:
        return tdee;
    }
  }

  /// Target Protein in grams based on dietary preference
  static double calculateTargetProtein(double targetCalories, [String preference = 'Balanced']) {
    double ratio = 0.25; // default 25%
    if (preference.toLowerCase().contains('high protein')) {
      ratio = 0.35;
    } else if (preference.toLowerCase().contains('low carb')) {
      ratio = 0.30;
    }
    return (targetCalories * ratio) / 4.0;
  }

  /// Target Carbs in grams based on dietary preference
  static double calculateTargetCarbs(double targetCalories, [String preference = 'Balanced']) {
    double ratio = 0.50; // default 50%
    if (preference.toLowerCase().contains('high protein')) {
      ratio = 0.40;
    } else if (preference.toLowerCase().contains('low carb')) {
      ratio = 0.20;
    }
    return (targetCalories * ratio) / 4.0;
  }

  /// Target Fat in grams based on dietary preference
  static double calculateTargetFat(double targetCalories, [String preference = 'Balanced']) {
    double ratio = 0.25; // default 25%
    if (preference.toLowerCase().contains('high protein')) {
      ratio = 0.25;
    } else if (preference.toLowerCase().contains('low carb')) {
      ratio = 0.50;
    }
    return (targetCalories * ratio) / 9.0;
  }
}
