import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/step_tracker_service.dart';
import '../theme/app_theme.dart';
import 'food_search_screen.dart';

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

    final progressRatio = (eatenCalories / targetCalories).clamp(0.0, 1.0);

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
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                        child: Text(
                          userProvider.profile.name.isNotEmpty
                              ? userProvider.profile.name[0].toUpperCase()
                              : 'N',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NativeNourish',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Hello, ${userProvider.profile.name}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Theme Toggle & Admin Quick Access
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme(!themeProvider.isDarkMode);
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 22),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("West African Nutrition Goal On Track!")),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 0, height: 24),

              // --- MAIN CALORIE SUMMARY CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E1F2C), Color(0xFF282A3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [AppColors.lightBluePrimary, AppColors.lightBlueSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : AppColors.lightBluePrimary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
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
                            Text(
                              'DAILY CALORIE GOAL',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${targetCalories.round()} kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'BMR: ${userProvider.bmr.round()} kcal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Calorie Circular Progress & Stats
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: progressRatio,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? AppColors.darkOrangePrimary : Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(progressRatio * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Eaten',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Stats Grid (Eaten, Burned, Remaining)
                        Expanded(
                          child: Column(
                            children: [
                              _buildMiniStatRow('Consumed', '${eatenCalories.round()} kcal', isDark ? AppColors.darkOrangePrimary : Colors.white),
                              const Divider(color: Colors.white24, height: 16),
                              _buildMiniStatRow('Burned (Steps & Ex)', '${burnedCalories.round()} kcal', AppColors.darkGreenAccent),
                              const Divider(color: Colors.white24, height: 16),
                              _buildMiniStatRow('Remaining', '${remainingCalories.round()} kcal', Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- HEALTH CARDS TITLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Health Cards',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
                      );
                    },
                    child: Text(
                      'Log Food',
                      style: TextStyle(
                        color: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- HEALTH CARD 1: STEP COUNTER ---
              _buildHealthCard(
                context,
                title: 'Daily Activity & Steps',
                subtitle: '${stepService.todaySteps} steps',
                icon: Icons.directions_walk_rounded,
                accentColor: AppColors.darkGreenAccent,
                trailing: '${stepService.estimatedStepCalories.round()} kcal burned',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
                      backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkGreenAccent),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Goal: 10,000 steps', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        Text('${(stepService.todaySteps * 0.00075).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- HEALTH CARD 2: MACRONUTRIENTS ---
              _buildHealthCard(
                context,
                title: 'Macronutrient Intake',
                subtitle: 'Protein / Carbs / Fat',
                icon: Icons.pie_chart_outline_rounded,
                accentColor: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                trailing: '${foodProvider.todayProtein.round()}g P',
                child: Column(
                  children: [
                    _buildMacroProgressBar(context, 'Protein', foodProvider.todayProtein, userProvider.targetProtein, AppColors.darkGreenAccent),
                    const SizedBox(height: 8),
                    _buildMacroProgressBar(context, 'Carbs', foodProvider.todayCarbs, userProvider.targetCarbs, isDark ? AppColors.darkBlueAccent : AppColors.lightBluePrimary),
                    const SizedBox(height: 8),
                    _buildMacroProgressBar(context, 'Fat', foodProvider.todayFat, userProvider.targetFat, isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- TODAY'S MEAL DIARY LOGS ---
              Text(
                "Today's Meals",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              foodProvider.todayMealLogs.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.restaurant_rounded, size: 40, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              const SizedBox(height: 8),
                              const Text('No meals logged yet today.'),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Log Food" to search West African dishes!',
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: foodProvider.todayMealLogs.length,
                      itemBuilder: (context, index) {
                        final log = foodProvider.todayMealLogs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                              child: Icon(
                                _getMealIcon(log.mealType),
                                color: isDark ? AppColors.darkOrangePrimary : AppColors.lightBluePrimary,
                              ),
                            ),
                            title: Text(log.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${log.mealType} • ${log.servings} serving(s)\nP: ${log.protein.round()}g | C: ${log.carbs.round()}g | F: ${log.fat.round()}g'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${log.totalCalories.round()} kcal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkGreenAccent : AppColors.lightBluePrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (log.id != null) foodProvider.deleteMealLog(log.id!);
                                  },
                                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHealthCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String trailing,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailing,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProgressBar(BuildContext context, String label, double current, double target, Color color) {
    final ratio = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(width: 55, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 65,
          child: Text(
            '${current.round()}/${target.round()}g',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
      default:
        return Icons.bakery_dining_rounded;
    }
  }
}
