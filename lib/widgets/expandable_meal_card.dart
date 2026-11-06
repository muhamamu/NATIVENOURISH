import 'package:flutter/material.dart';
import '../models/meal_log.dart';
import '../theme/app_theme.dart';
import 'bouncing_button.dart';

class ExpandableMealCard extends StatefulWidget {
  final MealLog meal;
  final VoidCallback onDelete;

  const ExpandableMealCard({
    super.key,
    required this.meal,
    required this.onDelete,
  });

  @override
  State<ExpandableMealCard> createState() => _ExpandableMealCardState();
}

class _ExpandableMealCardState extends State<ExpandableMealCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meal = widget.meal;

    final totalMacros = meal.protein + meal.carbs + meal.fat;
    final pPct = totalMacros > 0 ? (meal.protein / totalMacros * 100).round() : 0;
    final cPct = totalMacros > 0 ? (meal.carbs / totalMacros * 100).round() : 0;
    final fPct = totalMacros > 0 ? (meal.fat / totalMacros * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getMealColor(meal.mealType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getMealIcon(meal.mealType),
                      color: _getMealColor(meal.mealType),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.foodName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                meal.mealType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getMealColor(meal.mealType),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${meal.servings} serving(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${meal.totalCalories.round()} kcal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? AppColors.accentGreen : AppColors.primaryOrange,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroPill('Protein', '${meal.protein.round()}g', '$pPct%', AppColors.accentGreen),
                          _buildMacroPill('Carbs', '${meal.carbs.round()}g', '$cPct%', AppColors.accentBlue),
                          _buildMacroPill('Fat', '${meal.fat.round()}g', '$fPct%', AppColors.accentAmber),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Logged on ${meal.loggedAt}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          BouncingButton(
                            onTap: () {
                              _confirmDelete(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Logged Meal?'),
        content: Text('Are you sure you want to remove "${widget.meal.foodName}" from today\'s food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String grams, String percent, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(grams, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(percent, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Color _getMealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return AppColors.accentAmber;
      case 'lunch':
        return AppColors.primaryOrange;
      case 'dinner':
        return AppColors.accentPurple;
      case 'snack':
      default:
        return AppColors.accentGreen;
    }
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
