class ActivityLog {
  final int? id;
  final String activityName;
  final int durationMinutes;
  final double caloriesBurned;
  final int stepsCount;
  final String loggedAt; // YYYY-MM-DD

  ActivityLog({
    this.id,
    required this.activityName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.stepsCount,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_name': activityName,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'steps_count': stepsCount,
      'logged_at': loggedAt,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      activityName: map['activity_name'] as String,
      durationMinutes: map['duration_minutes'] as int,
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      stepsCount: map['steps_count'] as int,
      loggedAt: map['logged_at'] as String,
    );
  }
}
