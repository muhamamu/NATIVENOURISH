import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/profile_avatar.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import 'admin_food_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ImagePicker? imagePicker;
  const ProfileScreen({super.key, this.imagePicker});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = userProvider.profile;

    final targetWeightDiff = profile.displayWeight - profile.displayTargetWeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Align(alignment: Alignment.topCenter, child: SizedBox(width: 860, child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryAccent.withValues(alpha: isDark ? 0.2 : 0.09),
                  isDark ? AppColors.darkCardBg : Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.25)),
              ),
              child: Column(children: [
                Stack(alignment: Alignment.center, children: [
                  ProfileAvatar(profile: profile, size: 96),
                  if (_savingPhoto) const CircularProgressIndicator(),
                ]),
                const SizedBox(height: 10),
                TextButton.icon(onPressed: _savingPhoto ? null : () => _showAvatarPicker(userProvider),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16), label: const Text('Change photo')),
                Text(profile.name, textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const SizedBox(height: 8),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  Chip(label: Text('${profile.age} years'), visualDensity: VisualDensity.compact),
                  Chip(label: Text(profile.fitnessGoal == 'lose' ? 'Weight loss' : profile.fitnessGoal == 'gain' ? 'Build strength' : 'Maintain balance'),
                    visualDensity: VisualDensity.compact),
                ]),
                const SizedBox(height: 8),
                Text(profile.dietaryPreference, textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ]),
            ),
            const SizedBox(height: 24),

            // --- WEIGHT PROGRESS & BMI TRACKER ---
            Row(
              children: [
                // Current Weight Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Weight', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              profile.displayWeight.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(profile.weightUnit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${profile.displayTargetWeight.toStringAsFixed(1)} ${profile.weightUnit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // BMI Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Body Mass Index (BMI)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              profile.bmi.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                            ),
                            const SizedBox(width: 4),
                            const Text('kg/m²', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.bmiCategory,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Weight Difference Tracker Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(
                        targetWeightDiff.abs() < 0.2
                            ? 'Goal Achieved!'
                            : profile.fitnessGoal == 'maintain' ? 'Maintain your current weight' : (targetWeightDiff > 0
                                ? '${targetWeightDiff.toStringAsFixed(1)} ${profile.weightUnit} to lose'
                                : '${(-targetWeightDiff).toStringAsFixed(1)} ${profile.weightUnit} to gain'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      )),
                      const SizedBox(width: 12),
                      BouncingButton(
                        onTap: () => _showLogWeightDialog(context, userProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: AppColors.primaryAccent),
                              SizedBox(width: 2),
                              Text('Log Weight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryAccent)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (1.0 - ((profile.weightKg - profile.targetWeightKg).abs() / 15.0)).clamp(0.1, 1.0),
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- NUTRITIONAL TARGET BREAKDOWN CARD ---
            Text('Daily Target Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildCalorieStat('BMR', '${userProvider.bmr.round()}', 'Base burn', Colors.grey)),
                      Expanded(child: _buildCalorieStat('TDEE', '${userProvider.tdee.round()}', 'Total burn', AppColors.accentBlue)),
                      Expanded(child: _buildCalorieStat('Target', '${userProvider.dailyCalorieTarget.round()}', 'Daily Goal', AppColors.primaryAccent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildMacroTarget('Protein', '${userProvider.targetProtein.round()}g', '${(userProvider.targetProtein * 4).round()} kcal', AppColors.accentGreen)),
                      Expanded(child: _buildMacroTarget('Carbs', '${userProvider.targetCarbs.round()}g', '${(userProvider.targetCarbs * 4).round()} kcal', AppColors.accentBlue)),
                      Expanded(child: _buildMacroTarget('Fat', '${userProvider.targetFat.round()}g', '${(userProvider.targetFat * 9).round()} kcal', AppColors.accentAmber)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- EDIT PROFILE SETTINGS BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccentDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                label: const Text('Edit Personal Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  _showEditProfileModal(context, userProvider);
                },
              ),
            ),

            const SizedBox(height: 14),

            // Admin Food Database Launcher
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.admin_panel_settings_rounded),
              label: const Text('Admin Database Manager'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminFoodScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ))),
    );
  }

  Widget _buildCalorieStat(String label, String value, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Text('$value kcal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMacroTarget(String name, String grams, String cals, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(grams, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(cals, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Future<void> _showAvatarPicker(UserProvider provider) async {
    final action = await showModalBottomSheet<String>(context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Your profile photo', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Choose a photo from your device. It stays in this app.')),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Upload photo'),
          onTap: () => Navigator.pop(sheetContext, 'upload')),
        if (provider.profile.profileImage.startsWith('data:image/'))
          ListTile(leading: const Icon(Icons.person_outline), title: const Text('Remove photo'),
            onTap: () => Navigator.pop(sheetContext, 'remove')),
      ])));
    if (action == null || !mounted) return;
    setState(() => _savingPhoto = true);
    try {
      if (action == 'remove') {
        await provider.updateProfile(provider.profile.copyWith(profileImage: 'avatar_1'));
      } else {
        final file = await (widget.imagePicker ?? ImagePicker()).pickImage(source: ImageSource.gallery,
          maxWidth: 512, maxHeight: 512, imageQuality: 80);
        if (file == null) return;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
          throw const FormatException('Choose an image smaller than 5 MB.');
        }
        final decoded = await decodeImageFromList(bytes);
        decoded.dispose();
        await provider.updateProfile(provider.profile.copyWith(profileImage: 'data:image/jpeg;base64,${base64Encode(bytes)}'));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the photo. Choose an image smaller than 5 MB and try again.')));
      }
    } finally { if (mounted) setState(() => _savingPhoto = false); }
  }

  void _showLogWeightDialog(BuildContext context, UserProvider provider) {
    final weightController = TextEditingController(text: provider.profile.displayWeight.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log New Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your latest scale measurement to track your body weight trend over time.'),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (${provider.profile.weightUnit})',
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            onPressed: () {
              final val = double.tryParse(weightController.text);
              if (val != null && val.isFinite && val > 0) {
                provider.logWeight(provider.profile.weightInputToKg(val));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged weight: $val ${provider.profile.weightUnit}')),
                );
              }
            },
            child: const Text('Save Weight', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, UserProvider provider) {
    final profile = provider.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final ageCtrl = TextEditingController(text: profile.age.toString());
    final heightCtrl = TextEditingController(text: profile.heightCm.round().toString());
    final weightCtrl = TextEditingController(text: profile.weightKg.round().toString());
    final targetWeightCtrl = TextEditingController(text: profile.targetWeightKg.round().toString());

    String gender = profile.gender;
    String activity = profile.activityLevel;
    String goal = profile.fitnessGoal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Age (yrs)', prefixIcon: Icon(Icons.cake_outlined)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: gender,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'male', child: Text('Male')),
                                  DropdownMenuItem(value: 'female', child: Text('Female')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => gender = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_rounded)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Current Wt (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: targetWeightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Weight (kg)', prefixIcon: Icon(Icons.track_changes_rounded)),
                    ),
                    const SizedBox(height: 16),

                    const Text('Activity Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoice('Sedentary', 'sedentary', activity, (v) => setModalState(() => activity = v)),
                        _buildChoice('Lightly Active', 'light', activity, (v) => setModalState(() => activity = v)),
                        _buildChoice('Moderate (3-5d)', 'moderate', activity, (v) => setModalState(() => activity = v)),
                        _buildChoice('Active (6-7d)', 'active', activity, (v) => setModalState(() => activity = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Fitness Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildChoice('Weight Loss', 'lose', goal, (v) => setModalState(() => goal = v)),
                        _buildChoice('Maintain', 'maintain', goal, (v) => setModalState(() => goal = v)),
                        _buildChoice('Weight Gain', 'gain', goal, (v) => setModalState(() => goal = v)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                        onPressed: () {
                          final updated = profile.copyWith(
                            name: nameCtrl.text.trim(),
                            age: int.tryParse(ageCtrl.text) ?? profile.age,
                            gender: gender,
                            heightCm: double.tryParse(heightCtrl.text) ?? profile.heightCm,
                            weightKg: double.tryParse(weightCtrl.text) ?? profile.weightKg,
                            targetWeightKg: double.tryParse(targetWeightCtrl.text) ?? profile.targetWeightKg,
                            activityLevel: activity,
                            fitnessGoal: goal,
                          );
                          provider.updateProfile(updated);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile and metabolic targets updated!')),
                          );
                        },
                        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoice(String label, String value, String groupValue, Function(String) onSelect) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
      onSelected: (sel) {
        if (sel) onSelect(value);
      },
    );
  }
}
