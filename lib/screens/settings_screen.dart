import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/fasting_provider.dart';
import '../services/step_tracker_service.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) return;
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _cameraGranted = status.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    if (!mounted) return;
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
      body: Align(alignment: Alignment.topCenter, child: SizedBox(width: 860, child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 24), child: Row(children: [
              ProfileAvatar(profile: profile, size: 52),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const Text('Make NativeNourish feel like you', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
            ])),
            // --- SECTION 1: APPEARANCE & THEME ---
            _buildSectionHeader('Appearance & Theme', Icons.palette_outlined),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('A softer dark palette for comfortable viewing'),
                    secondary: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primaryAccent,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  ),
                  const Divider(height: 1),
                  Padding(padding: const EdgeInsets.all(16), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('App accent', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Choose a color for buttons, navigation, and highlights.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 8, children: [
                        for (final entry in AppColors.accentColors.entries)
                          ChoiceChip(label: Text(entry.key),
                            avatar: CircleAvatar(backgroundColor: entry.value, radius: 8),
                            selected: themeProvider.accentName == entry.key,
                            onSelected: (_) async {
                              try { await themeProvider.setAccent(entry.key); }
                              catch (_) { if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not save appearance. Please try again.'))); } }
                            }),
                      ]),
                  ])),
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
                          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
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

            _buildSectionHeader('Smart Notifications', Icons.notifications_none_rounded),
            const Card(child: ListTile(
              leading: Icon(Icons.schedule_outlined), title: Text('Reminders coming soon'),
              subtitle: Text('Meal and hydration reminders are not available yet. Track your daily progress from the dashboard.'),
            )),
            const SizedBox(height: 20),

            // --- SECTION 5: HARDWARE & PERMISSIONS ---
            _buildSectionHeader('Hardware & Permissions', Icons.security_rounded),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentBlue),
                    title: const Text('Camera & Photo Access'),
                    subtitle: Text(kIsWeb ? 'Your browser asks before using the camera. Photo uploads use the file picker.' : _cameraGranted ? 'Camera access granted' : 'Permission needed to take a photo'),
                    trailing: kIsWeb ? null : _cameraGranted
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen)
                        : TextButton(
                            onPressed: _requestCameraPermission,
                            child: const Text('Enable'),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.directions_walk_rounded, color: AppColors.accentGreen),
                    title: const Text('Activity & Step Sensors'),
                    subtitle: Text(kIsWeb ? 'Manual steps are available in the browser.' : 'Connect your device sensor from the Activity screen.'),
                    trailing: const Icon(Icons.directions_walk_rounded, color: AppColors.accentGreen),
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
                    'West African Nutrition & Calorie Tracker',
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
      ))),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryAccent),
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
              final activityProvider = context.read<ActivityProvider>();
              final recipeProvider = context.read<RecipeProvider>();
              final fastingProvider = context.read<FastingProvider>();
              final stepTracker = context.read<StepTrackerService>();
              await DatabaseHelper.instance.resetToDefaults();
              await foodProvider.loadInitialData();
              await userProvider.loadUserProfile();
              await activityProvider.loadTodayActivities();
              await recipeProvider.loadRecipes();
              await fastingProvider.loadActiveFast();
              await stepTracker.resetCounts();
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
