import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import 'bouncing_button.dart';

class InteractiveWaterCard extends StatelessWidget {
  const InteractiveWaterCard({super.key});

  void _showCustomWaterDialog(BuildContext context, FoodProvider foodProvider) {
    final controller = TextEditingController(text: '300');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Custom Water'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Water Amount (ml)',
            prefixIcon: Icon(Icons.water_drop_outlined, color: AppColors.accentBlue),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                foodProvider.addWater(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Log Water', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetWater = userProvider.profile.dailyWaterTargetMl;
    final currentWater = foodProvider.todayWaterMl;
    final ratio = targetWater > 0 ? (currentWater / targetWater).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentBlue,
                          AppColors.accentBlue.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hydration Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Target: ${(targetWater / 1000).toStringAsFixed(1)}L per day', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: pct.toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${val.round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentBlue),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fluid Animated Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: currentWater),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return Text(
                    '${val.round()} ml',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  );
                },
              ),
              Text(
                '${(targetWater - currentWater).clamp(0.0, 9999.0).round()} ml remaining',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Smooth Animated Fluid Progress Bar with Liquid Glow
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animatedRatio, _) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animatedRatio.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF29B6F6),
                            AppColors.accentBlue,
                            Color(0xFF0288D1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Quick Action Log Buttons with Micro-Interactions
          Row(
            children: [
              Expanded(
                child: BouncingButton(
                  onTap: () => foodProvider.addWater(250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_drink_rounded, size: 16, color: AppColors.accentBlue),
                        SizedBox(width: 4),
                        Text('+250 ml (Glass)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncingButton(
                  onTap: () => foodProvider.addWater(500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_rounded, size: 16, color: AppColors.accentBlue),
                        SizedBox(width: 4),
                        Text('+500 ml (Bottle)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20, color: Colors.grey),
                tooltip: 'Undo last water log',
                onPressed: () => foodProvider.removeLastWater(),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.accentBlue),
                tooltip: 'Custom amount',
                onPressed: () => _showCustomWaterDialog(context, foodProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
