import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/theme_provider.dart';
import '../services/step_tracker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/animated_radial_rings.dart';
import '../widgets/expandable_meal_card.dart';
import '../widgets/external_animation_view.dart';
import '../widgets/interactive_water_card.dart';
import '../widgets/profile_avatar.dart';
import 'food_search_screen.dart';
import 'ai_food_scanner_screen.dart';
import 'recipe_discovery_screen.dart';
import 'manual_food_entry_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final stepService = Provider.of<StepTrackerService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetCalories = userProvider.dailyCalorieTarget;
    final eatenCalories = foodProvider.todayCalories;
    final burnedCalories = activityProvider.todayBurnedCalories + stepService.estimatedStepCalories;
    final remainingCalories = (targetCalories - eatenCalories + burnedCalories).clamp(0.0, 9999.0);

    final calorieRatio = targetCalories > 0 ? (eatenCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
    final proteinRatio = userProvider.targetProtein > 0 ? (foodProvider.todayProtein / userProvider.targetProtein).clamp(0.0, 1.0) : 0.0;
    final carbsRatio = userProvider.targetCarbs > 0 ? (foodProvider.todayCarbs / userProvider.targetCarbs).clamp(0.0, 1.0) : 0.0;
    final fatRatio = userProvider.targetFat > 0 ? (foodProvider.todayFat / userProvider.targetFat).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER BAR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(profile: userProvider.profile, size: 48),
                  const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'NativeNourish',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LOCAL DATA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hello, ${userProvider.profile.name.split(' ').first}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 19,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Quick Action Controls
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: isDark ? AppColors.primaryAccent : AppColors.lightTextPrimary,
                          size: 22,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme(!themeProvider.isDarkMode);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- MAIN HERO NUTRITION CARD (WITH ANIMATED RADIAL RINGS) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF161822), Color(0xFF1D202D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Colors.white, Color(0xFFF9FAFB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY CALORIE TARGET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${targetCalories.round()} kcal',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.primaryAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${burnedCalories.round()} kcal burned',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Central Radial Rings & Macro Metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AnimatedRadialRings(
                          size: 140,
                          calorieRatio: calorieRatio,
                          proteinRatio: proteinRatio,
                          carbsRatio: carbsRatio,
                          fatRatio: fatRatio,
                          eatenCalories: eatenCalories,
                          targetCalories: targetCalories,
                          remainingCalories: remainingCalories,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMacroRow(
                              'Protein',
                              '${foodProvider.todayProtein.round()} / ${userProvider.targetProtein.round()}g',
                              proteinRatio,
                              AppColors.accentGreen,
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildMacroRow(
                              'Carbs',
                              '${foodProvider.todayCarbs.round()} / ${userProvider.targetCarbs.round()}g',
                              carbsRatio,
                              AppColors.accentBlue,
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildMacroRow(
                              'Fat',
                              '${foodProvider.todayFat.round()} / ${userProvider.targetFat.round()}g',
                              fatRatio,
                              AppColors.accentAmber,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- QUICK ACTION LAUNCHERS (AI SCAN, SEARCH, RECIPES, MANUAL) ---
              Row(
                children: [
                  Expanded(
                    child: BouncingButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AiFoodScannerScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryAccentDark, AppColors.primaryAccentLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Scanner Demo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BouncingButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, color: isDark ? Colors.white : AppColors.lightTextPrimary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Search Foods',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
                    child: BouncingButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecipeDiscoveryScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, color: AppColors.accentBlue, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Recipes',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BouncingButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManualFoodEntryScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.accentGreen, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Manual Entry',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- HEALTH TILES (STEP COUNTER & HYDRATION) ---
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Counter Card
                  Expanded(
                    child: Container(
                      key: const ValueKey('steps-card'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_walk_rounded, color: AppColors.accentGreen, size: 20),
                              ),
                              Text(
                                '${((stepService.todaySteps / 10000) * 100).round()}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${stepService.todaySteps}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('Steps Today', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
                              backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Hydration uses the same saved daily totals as Food Log.
                  const Expanded(child: InteractiveWaterCard()),
                ],
                ),
              ),

              const SizedBox(height: 24),

              // --- TODAY'S MEAL DIARY (EXPANDABLE CARDS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Meals (${foodProvider.todayMealLogs.length})",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Meal'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              foodProvider.todayMealLogs.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          ExternalAnimationView(
                            assetPath: 'assets/animations/empty.json',
                            width: 90,
                            height: 90,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No meals logged yet today',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter a meal manually or search authentic dishes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Scan Meal Now'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AiFoodScannerScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: foodProvider.todayMealLogs.length,
                      itemBuilder: (context, index) {
                        final log = foodProvider.todayMealLogs[index];
                        return ExpandableMealCard(
                          meal: log,
                          onDelete: () {
                            if (log.id != null) foodProvider.deleteMealLog(log.id!);
                          },
                        );
                      },
                    ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, double ratio, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
