import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../theme/app_theme.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final target = userProvider.dailyCalorieTarget;
    final weeklySummary = foodProvider.weeklySummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritional Trends & Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TRENDS SUMMARY CARD ---
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
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Calorie Trend',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Daily intake vs 7-day target',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${target.round()} kcal Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weekly Bars Visualization
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(weeklySummary.length, (index) {
                        final day = weeklySummary[index];
                        final date = DateTime.parse(day['date'] as String);
                        final dayCal = (day['calories'] as num).toDouble();
                        final heightRatio = target > 0 ? (dayCal / (target * 1.3)).clamp(0.0, 1.0) : 0.0;
                        final now = DateTime.now();
                        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${dayCal.round()}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppColors.accentGreen : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: 110 * heightRatio,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isToday
                                      ? [AppColors.accentGreen, AppColors.accentGreenLight]
                                      : (isDark
                                          ? [AppColors.accentBlue, AppColors.darkCardHeader]
                                          : [AppColors.lightBluePrimary, AppColors.lightBlueAccent]),
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEE').format(date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday
                                    ? AppColors.primaryAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Macronutrient Distribution', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSummaryMacroRow('Protein', '${foodProvider.todayProtein.round()}g', '${userProvider.targetProtein.round()}g goal', AppColors.accentGreen),
                    const Divider(height: 24),
                    _buildSummaryMacroRow('Carbohydrates', '${foodProvider.todayCarbs.round()}g', '${userProvider.targetCarbs.round()}g goal', AppColors.accentBlue),
                    const Divider(height: 24),
                    _buildSummaryMacroRow('Fats', '${foodProvider.todayFat.round()}g', '${userProvider.targetFat.round()}g goal', AppColors.accentAmber),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Evidence-Based Nutrition Disclaimer Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined, color: AppColors.primaryAccent, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evidence-Based Nutritional Note',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nutritional content for regional West African foods is based on standard food composition tables. Actual calorie values vary according to specific ingredients, oil quantities, and culinary preparation methods.',
                          style: TextStyle(fontSize: 11, height: 1.4, color: Colors.grey),
                        ),
                      ],
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

  Widget _buildSummaryMacroRow(String label, String current, String target, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Text(current, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            const SizedBox(width: 6),
            Text('($target)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
