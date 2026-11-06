import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../services/step_tracker_service.dart';
import '../theme/app_theme.dart';

class DailySummaryDialog {
  static void show(
    BuildContext context, {
    required FoodProvider foodProvider,
    required UserProvider userProvider,
    required ActivityProvider activityProvider,
    required StepTrackerService stepService,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final target = userProvider.dailyCalorieTarget;
    final eaten = foodProvider.todayCalories;
    final burned = activityProvider.todayBurnedCalories + stepService.estimatedStepCalories;
    final net = eaten - burned;

    final p = foodProvider.todayProtein;
    final c = foodProvider.todayCarbs;
    final f = foodProvider.todayFat;
    final totalMacros = p + c + f;
    final pPct = totalMacros > 0 ? (p / totalMacros * 100).round() : 0;
    final cPct = totalMacros > 0 ? (c / totalMacros * 100).round() : 0;
    final fPct = totalMacros > 0 ? (f / totalMacros * 100).round() : 0;

    final summaryText = '''
NativeNourish Daily Nutrition Report - ${foodProvider.selectedDateDisplay}
----------------------------------------
Calorie Target: ${target.round()} kcal
Consumed: ${eaten.round()} kcal
Burned (Steps & Activity): ${burned.round()} kcal
Net Calories: ${net.round()} kcal

Macronutrient Breakdown:
- Protein: ${p.round()}g ($pPct%)
- Carbohydrates: ${c.round()}g ($cPct%)
- Fats: ${f.round()}g ($fPct%)

Hydration & Movement:
- Water: ${(foodProvider.todayWaterMl / 1000).toStringAsFixed(2)} L
- Steps: ${stepService.todaySteps} steps (${(stepService.todaySteps * 0.00075).toStringAsFixed(1)} km)
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_rounded, color: AppColors.primaryOrange, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Daily Nutrition Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                foodProvider.selectedDateDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildRow('Total Eaten', '${eaten.round()} kcal', isDark ? Colors.white : Colors.black87),
                    const SizedBox(height: 6),
                    _buildRow('Calorie Burned', '-${burned.round()} kcal', AppColors.accentGreen),
                    const Divider(height: 14),
                    _buildRow('Net Balance', '${net.round()} kcal', AppColors.primaryOrange, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Macronutrients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroTile('Protein', '${p.round()}g', '$pPct%', AppColors.accentGreen),
                  _buildMacroTile('Carbs', '${c.round()}g', '$cPct%', AppColors.accentBlue),
                  _buildMacroTile('Fat', '${f.round()}g', '$fPct%', AppColors.accentAmber),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Hydration & Movement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Water Intake: ${(foodProvider.todayWaterMl / 1000).toStringAsFixed(2)} L', style: const TextStyle(fontSize: 12)),
                  Text('Steps: ${stepService.todaySteps}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
            label: const Text('Copy Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summaryText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Daily nutrition summary copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildRow(String label, String val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  static Widget _buildMacroTile(String label, String grams, String pct, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(grams, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(pct, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
