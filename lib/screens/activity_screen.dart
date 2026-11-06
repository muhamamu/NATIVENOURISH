import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/step_tracker_service.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');
  final TextEditingController _caloriesController = TextEditingController(text: '200');

  final List<Map<String, dynamic>> _quickWorkouts = [
    {'name': 'Afrobeat Dancing', 'icon': Icons.music_note_rounded, 'calPerMin': 7.5},
    {'name': 'Football / Soccer', 'icon': Icons.sports_soccer_rounded, 'calPerMin': 8.5},
    {'name': 'Brisk Walking', 'icon': Icons.directions_walk_rounded, 'calPerMin': 4.5},
    {'name': 'Jogging / Running', 'icon': Icons.directions_run_rounded, 'calPerMin': 10.0},
    {'name': 'Gym / Weight Training', 'icon': Icons.fitness_center_rounded, 'calPerMin': 6.0},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StepTrackerService>(context, listen: false).initializeStepCounter();
    });
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepService = Provider.of<StepTrackerService>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Step Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MAIN STEP COUNTER CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF10B981).withValues(alpha: 0.25), AppColors.darkCardBg]
                      : [const Color(0xFF10B981).withValues(alpha: 0.12), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_walk_rounded, color: AppColors.accentGreen, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Step Sensor Live',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stepService.isListening ? 'Hardware Active' : 'Ready',
                          style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Big Steps Counter
                  Text(
                    '${stepService.todaySteps}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1),
                  ),
                  const Text(
                    'Daily Steps Completed',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                  const SizedBox(height: 18),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepStat('Distance', '${(stepService.todaySteps * 0.00075).toStringAsFixed(2)} km'),
                      _buildStepStat('Cal Burned', '~${stepService.estimatedStepCalories.round()} kcal'),
                      _buildStepStat('Daily Goal', '10,000 steps'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Quick emulator / test step increment
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Add +1,000 Steps (Manual / Sensor test)'),
                onPressed: () {
                  stepService.addManualSteps(1000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added +1,000 steps to daily progress!')),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Text('Quick Workout Logging', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Quick Workout Cards
            SizedBox(
              height: 94,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickWorkouts.length,
                itemBuilder: (context, index) {
                  final w = _quickWorkouts[index];
                  return BouncingButton(
                    onTap: () {
                      _activityNameController.text = w['name'];
                      _caloriesController.text = ((double.parse(_durationController.text)) * (w['calPerMin'] as double)).round().toString();
                    },
                    child: Container(
                      width: 114,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(w['icon'] as IconData, color: AppColors.primaryAccent, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            w['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Text('Custom Workout Entry', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _activityNameController,
                      decoration: const InputDecoration(
                        labelText: 'Activity Name (e.g. Football match, Afrobeat Class)',
                        prefixIcon: Icon(Icons.fitness_center_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (mins)',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Est. Cal Burned',
                              prefixIcon: Icon(Icons.local_fire_department_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final name = _activityNameController.text.trim();
                          final dur = int.tryParse(_durationController.text) ?? 30;
                          final cal = double.tryParse(_caloriesController.text) ?? 200.0;

                          if (name.isNotEmpty) {
                            activityProvider.logActivity(
                              activityName: name,
                              durationMinutes: dur,
                              caloriesBurned: cal,
                            );
                            _activityNameController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logged activity "$name" (-${cal.round()} kcal)!')),
                            );
                          }
                        },
                        child: const Text('Save Activity Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text("Today's Logged Workouts", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            activityProvider.todayActivityLogs.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: const Center(
                      child: Text('No custom workouts logged today yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activityProvider.todayActivityLogs.length,
                    itemBuilder: (context, index) {
                      final act = activityProvider.todayActivityLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_run_rounded, color: AppColors.accentGreen, size: 20),
                          ),
                          title: Text(act.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${act.durationMinutes} mins'),
                          trailing: Text(
                            '-${act.caloriesBurned.round()} kcal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.accentGreen),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
