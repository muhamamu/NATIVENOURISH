import 'dart:async';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class FastingProvider extends ChangeNotifier {
  bool _isFasting = false;
  DateTime? _startTime;
  int _targetHours = 16;
  Timer? _ticker;
  bool _disposed = false;
  List<Map<String, dynamic>> _history = [];

  bool get isFasting => _isFasting;
  DateTime? get startTime => _startTime;
  int get targetHours => _targetHours;
  List<Map<String, dynamic>> get history => _history;

  Duration get elapsedTime {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    return now.isAfter(_startTime!) ? now.difference(_startTime!) : Duration.zero;
  }

  Duration get remainingTime {
    final target = Duration(hours: _targetHours);
    final elapsed = elapsedTime;
    if (elapsed >= target) return Duration.zero;
    return target - elapsed;
  }

  double get progressRatio {
    if (!_isFasting || _startTime == null || _targetHours <= 0) return 0.0;
    final totalSec = _targetHours * 3600;
    final elapsedSec = elapsedTime.inSeconds;
    return (elapsedSec / totalSec).clamp(0.0, 1.0);
  }

  String get fastingStage {
    final hours = elapsedTime.inHours;
    if (hours < 4) return 'Blood Sugar Stabilizing';
    if (hours < 8) return 'Glycogen Depletion';
    if (hours < 12) return 'Fat Burning Mode';
    if (hours < 16) return 'Ketosis Triggered';
    return 'Autophagy & Cellular Repair';
  }

  FastingProvider() {
    loadActiveFast();
  }

  Future<void> loadActiveFast() async {
    _ticker?.cancel();
    final active = await DatabaseHelper.instance.getActiveFast();
    if (active != null) {
      _isFasting = true;
      _startTime = DateTime.tryParse(active['start_time'] as String? ?? '');
      _targetHours = (active['target_hours'] as int?) ?? 16;
      if (!_disposed) _startTicker();
    } else {
      _isFasting = false;
      _startTime = null;
    }
    _history = await DatabaseHelper.instance.getFastingHistory();
    if (!_disposed) notifyListeners();
  }

  void setPreset(int hours) {
    _targetHours = hours;
    notifyListeners();
  }

  Future<void> startFast([int? hours]) async {
    final target = hours ?? _targetHours;
    _targetHours = target;
    final now = DateTime.now();
    _startTime = now;
    _isFasting = true;

    await DatabaseHelper.instance.startFast(now, target);
    _startTicker();
    notifyListeners();
  }

  Future<void> endFast() async {
    _ticker?.cancel();
    _isFasting = false;
    await DatabaseHelper.instance.endFast(DateTime.now());
    _startTime = null;
    _history = await DatabaseHelper.instance.getFastingHistory();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
