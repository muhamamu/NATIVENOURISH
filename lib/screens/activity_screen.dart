import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_tracker_service.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MAIN STEP COUNTER CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF10B981).withOpacity(0.2), AppColors.darkCardBg]
                      : [AppColors.lightBluePrimary, AppColors.lightBlueSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreenAccent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_walk_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Step Counter Hardware',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stepService.isListening ? 'Sensor Active' : 'Sensor Ready',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Steps Big Counter
                  Text(
                    '${stepService.todaySteps}',
                    style: const TextStyle(color: Colors.white, fontSize: 44, FontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Daily Steps Completed',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkGreenAccent),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStepSubStat('Distance', '${(stepService.todaySteps * 0.00075).toStringAsFixed(2)} km'),
                      _buildStepSubStat('Calories Burned', '~${stepService.estimatedStepCalories.round()} kcal'),
                      _buildStepSubStat('Target', '10,000 steps'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Manual Step Adder button (For emulators or adjustment)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Add 1,000 Steps (Manual / Emulator test)'),
                onPressed: () {
                  stepService.addManualSteps(1000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added +1,000 steps to daily total!')),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Text('Quick Workout Logging', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Quick Workout Chips
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickWorkouts.length,
                itemBuilder: (context, index) {
                  final w = _quickWorkouts[index];
                  return GestureDetector(
                    onTap: () {
                      _activityNameController.text = w['name'];
                      _caloriesController.text = ((double.parse(_durationController.text)) * (w['calPerMin'] as double)).round().toString();
                    },
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : AppColors.lightCardHeader,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(w['icon'] as IconData, color: isDark ? AppColors.darkOrangePrimary : AppColors.lightOrange, size: 24),
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
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreenAccent,
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
                              SnackBar(content: Text('Logged activity "$name" ($cal kcal)!')),
                            );
                          }
                        },
                        child: const Text('Save Activity Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No custom workouts logged today yet.')),
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
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.darkGreenAccent,
                            child: Icon(Icons.directions_run_rounded, color: Colors.white),
                          ),
                          title: Text(act.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${act.durationMinutes} mins'),
                          trailing: Text(
                            '-${act.caloriesBurned.round()} kcal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkGreenAccent),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepSubStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
