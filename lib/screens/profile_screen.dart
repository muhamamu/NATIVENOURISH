import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'admin_food_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _fitnessGoal = 'maintain';

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<UserProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.heightCm.round().toString());
    _weightController = TextEditingController(text: profile.weightKg.round().toString());
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _fitnessGoal = profile.fitnessGoal;
  }

  @override