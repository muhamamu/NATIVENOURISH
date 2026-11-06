import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _breakfastReminder = true;
  bool _lunchReminder = true;
  bool _dinnerReminder = true;
  bool _hydrationReminder = true;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraGranted = status.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    setState(() {
      _cameraGranted = result.isGranted;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cameraGranted ? 'Camera permission granted!' : 'Camera permission denied.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = userProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: APPEARANCE & THEME ---
            _buildSectionHeader('Appearance & Theme', Icons.palette_outlined),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('OLED obsidian palette with vibrant orange accents'),
                    secondary: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primaryOrange,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 2: MEASUREMENT UNITS ---
            _buildSectionHeader('Measurement Units', Icons.straighten_rounded),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Weight Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(profile.weightUnit == 'kg' ? 'Metric (Kilograms - kg)' : 'Imperial (Pounds - lbs)'),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'kg', label: Text('kg')),
                        ButtonSegment(value: 'lbs', label: Text('lbs')),
                      ],
                      selected: {profile.weightUnit},
                      onSelectionChanged: (val) {
                        userProvider.updateProfile(profile.copyWith(weightUnit: val.first));
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Height Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(profile.heightUnit == 'cm' ? 'Metric (Centimeters - cm)' : 'Imperial (Inches - in)'),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'cm', label: Text('cm')),
                        ButtonSegment(value: 'in', label: Text('in')),
                      ],
                      selected: {profile.heightUnit},
                      onSelectionChanged: (val) {
                        userProvider.updateProfile(profile.copyWith(heightUnit: val.first));
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 3: DIETARY PREFERENCES ---
            _buildSectionHeader('Dietary Preferences', Icons.restaurant_menu_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nutritional Macro Split Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Controls your daily target protein, carbohydrate, and fat calculations.',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'West African Heritage',
                        'High Protein',
                        'Balanced',
                        'Low Carb',
                      ].map((pref) {
                        final isSel = profile.dietaryPreference == pref;
                        return ChoiceChip(
                          label: Text(pref),
                          selected: isSel,
                          selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                          onSelected: (val) {
                            if (val) {
                              userProvider.updateProfile(profile.copyWith(dietaryPreference: pref));
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 4: NOTIFICATIONS & REMINDERS ---
            _buildSectionHeader('Smart Notifications', Icons.notifications_active_outlined),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Breakfast Logging Reminder'),
                    subtitle: const Text('8:00 AM prompt to record your morning meal'),
                    value: _breakfastReminder,
                    onChanged: (val) => setState(() => _breakfastReminder = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Lunch Logging Reminder'),
                    subtitle: const Text('1:00 PM midday meal tracking reminder'),
                    value: _lunchReminder,
                    onChanged: (val) => setState(() => _lunchReminder = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dinner Logging Reminder'),
                    subtitle: const Text('7:30 PM evening meal review prompt'),
                    value: _dinnerReminder,
                    onChanged: (val) => setState(() => _dinnerReminder = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Hydration Reminder'),
                    subtitle: const Text('Periodic reminders to drink water and reach 2.5L'),
                    value: _hydrationReminder,
                    onChanged: (val) => setState(() => _hydrationReminder = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 5: HARDWARE & PERMISSIONS ---
            _buildSectionHeader('Hardware & Permissions', Icons.security_rounded),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentBlue),
                    title: const Text('Camera & Photo Access'),
                    subtitle: Text(_cameraGranted ? 'Access Granted for AI Food Scanner' : 'Permission needed for AI food scanning'),
                    trailing: _cameraGranted
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen)
                        : TextButton(
                            onPressed: _requestCameraPermission,
                            child: const Text('Enable'),
                          ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.directions_walk_rounded, color: AppColors.accentGreen),
                    title: Text('Activity & Step Sensors'),
                    subtitle: Text('Tracks active steps & estimated caloric burn on-device'),
                    trailing: Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SECTION 6: PRIVACY & DATA GUARANTEE ---
            _buildSectionHeader('Privacy & Data Management', Icons.folder_shared_outlined),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline_rounded, color: AppColors.accentGreen),
                    title: Text('Offline-First Architecture'),
                    subtitle: Text('Your nutrition logs and biometric profiles are stored securely in local SQLite databases.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.accentAmber),
                    title: const Text("Clear Today's Meal Logs"),
                    subtitle: const Text('Reset food entries for today while preserving historical data'),
                    onTap: () {
                      _confirmClearToday(context, foodProvider);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: const Text('Reset All User Data', style: TextStyle(color: Colors.redAccent)),
                    subtitle: const Text('Erase custom dishes, meal history, and reset to defaults'),
                    onTap: () {
                      _confirmResetAll(context, foodProvider, userProvider);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Application Version Info
            Center(
              child: Column(
                children: [
                  Text(
                    'NativeNourish v1.0.0+1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'West African Nutrition & AI Calorie Tracker',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryOrange),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _confirmClearToday(BuildContext context, FoodProvider foodProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Today's Meals?"),
        content: const Text("This will remove all logged meals recorded for today. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var meal in List.from(foodProvider.todayMealLogs)) {
                if (meal.id != null) await foodProvider.deleteMealLog(meal.id!);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cleared today's meal logs.")),
                );
              }
            },
            child: const Text('Clear Today', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll(BuildContext context, FoodProvider foodProvider, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text('Are you sure you want to reset all meal logs, activity records, and custom dishes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.resetToDefaults();
              await foodProvider.loadInitialData();
              await userProvider.loadUserProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset to defaults.')),
                );
              }
            },
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
