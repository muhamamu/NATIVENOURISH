class UserProfile {
  final int id;
  final String name;
  final int age;
  final String gender; // 'male' | 'female'
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active'
  final String fitnessGoal; // 'lose', 'maintain', 'gain'
  final String profileImage;
  final String weightUnit; // 'kg' | 'lbs'
  final String heightUnit; // 'cm' | 'in'
  final String dietaryPreference; // 'Balanced', 'High Protein', 'Low Carb', 'West African Heritage'
  final double dailyWaterTargetMl;

  UserProfile({
    this.id = 1,
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    double? targetWeightKg,
    required this.activityLevel,
    required this.fitnessGoal,
    this.profileImage = 'assets/avatar_1.png',
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.dietaryPreference = 'West African Heritage',
    this.dailyWaterTargetMl = 2500,
  }) : targetWeightKg = targetWeightKg ?? weightKg;

  static const double poundsPerKilogram = 2.2046226218;

  double get displayWeight => weightUnit == 'lbs' ? weightKg * poundsPerKilogram : weightKg;
  double get displayTargetWeight => weightUnit == 'lbs' ? targetWeightKg * poundsPerKilogram : targetWeightKg;
  double weightInputToKg(double value) => weightUnit == 'lbs' ? value / poundsPerKilogram : value;

  double get bmi {
    if (heightCm <= 0) return 22.0;
    final heightInMeters = heightCm / 100.0;
    return weightKg / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Healthy Weight';
    if (val < 30.0) return 'Overweight';
    return 'Obese';
  }

  double get weightDifferenceFromTarget => weightKg - targetWeightKg;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_weight_kg': targetWeightKg,
      'activity_level': activityLevel,
      'fitness_goal': fitnessGoal,
      'profile_image': profileImage,
      'weight_unit': weightUnit,
      'height_unit': heightUnit,
      'dietary_preference': dietaryPreference,
      'daily_water_target_ml': dailyWaterTargetMl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final wKg = (map['weight_kg'] as num?)?.toDouble() ?? 70.0;
    final tKg = (map['target_weight_kg'] as num?)?.toDouble() ?? wKg;

    return UserProfile(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'NativeNourish User',
      age: map['age'] as int? ?? 26,
      gender: map['gender'] as String? ?? 'male',
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 175.0,
      weightKg: wKg,
      targetWeightKg: tKg,
      activityLevel: map['activity_level'] as String? ?? 'moderate',
      fitnessGoal: map['fitness_goal'] as String? ?? 'maintain',
      profileImage: map['profile_image'] as String? ?? 'assets/avatar_1.png',
      weightUnit: map['weight_unit'] as String? ?? 'kg',
      heightUnit: map['height_unit'] as String? ?? 'cm',
      dietaryPreference: map['dietary_preference'] as String? ?? 'West African Heritage',
      dailyWaterTargetMl: (map['daily_water_target_ml'] as num?)?.toDouble() ?? 2500,
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? fitnessGoal,
    String? profileImage,
    String? weightUnit,
    String? heightUnit,
    String? dietaryPreference,
    double? dailyWaterTargetMl,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      profileImage: profileImage ?? this.profileImage,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      dailyWaterTargetMl: dailyWaterTargetMl ?? this.dailyWaterTargetMl,
    );
  }
}
