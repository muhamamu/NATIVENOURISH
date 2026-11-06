import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fasting_provider.dart';
import '../theme/app_theme.dart';

class FastingScreen extends StatelessWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fastingProvider = Provider.of<FastingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFasting = fastingProvider.isFasting;
    final elapsed = fastingProvider.elapsedTime;
    final remaining = fastingProvider.remainingTime;
    final ratio = fastingProvider.progressRatio;

    final elapsedStr = '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    final remainingStr = '${remaining.inHours}h ${remaining.inMinutes % 60}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermittent Fasting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Preset Selector Chips
            if (!isFasting) ...[
              const Text('Select Fasting Protocol:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPresetChip(context, '14:10', 14, fastingProvider),
                  _buildPresetChip(context, '16:8 (Popular)', 16, fastingProvider),
                  _buildPresetChip(context, '18:6', 18, fastingProvider),
                  _buildPresetChip(context, '20:4', 20, fastingProvider),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Main Circular Fasting Clock Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
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
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: isFasting ? ratio : 0.0,
                            strokeWidth: 14,
                            backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ratio >= 1.0 ? AppColors.accentGreen : AppColors.primaryAccent,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isFasting ? (ratio >= 1.0 ? 'Goal Reached!' : 'Fasting') : 'Ready to Fast',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isFasting
                                    ? (ratio >= 1.0 ? AppColors.accentGreen : AppColors.primaryAccent)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFasting ? elapsedStr : '${fastingProvider.targetHours}h 00m',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFasting ? '$remainingStr remaining' : 'Target Fast Window',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Current Metabolic Stage Badge
                  if (isFasting) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Stage: ${fastingProvider.fastingStage}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFasting ? Colors.redAccent : AppColors.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(isFasting ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white),
                      label: Text(
                        isFasting ? 'End Fast & Open Window' : 'Start Fasting (${fastingProvider.targetHours}h)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        if (isFasting) {
                          _confirmEndFast(context, fastingProvider);
                        } else {
                          fastingProvider.startFast();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metabolic Stage Timeline Guide
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metabolic Fasting Phases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildPhaseItem('0 - 4h', 'Blood Sugar Stabilization', 'Insulin levels begin dropping as digestion finishes.', AppColors.accentBlue),
                  _buildPhaseItem('4 - 8h', 'Glycogen Depletion', 'Body exhausts stored liver glucose and shifts fuel sources.', AppColors.accentAmber),
                  _buildPhaseItem('8 - 12h', 'Fat Burning Activated', 'Lipolysis accelerates as fat stores convert to energy.', AppColors.primaryAccent),
                  _buildPhaseItem('12 - 16h+', 'Ketosis & Autophagy', 'Ketone production peaks and cellular clean-up initiates.', AppColors.accentGreen),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, int hours, FastingProvider provider) {
    final isSel = provider.targetHours == hours;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
      onSelected: (_) => provider.setPreset(hours),
    );
  }

  Widget _buildPhaseItem(String hours, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(hours, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndFast(BuildContext context, FastingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Fast?'),
        content: const Text('Are you ready to break your fast and open your eating window?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            onPressed: () {
              provider.endFast();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fast completed and saved to history!')),
              );
            },
            child: const Text('End Fast', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
