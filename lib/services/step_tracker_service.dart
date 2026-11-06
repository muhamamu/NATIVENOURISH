import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/db_helper.dart';

typedef ReadStepCounts = Future<Map<String, dynamic>?> Function(String date);
typedef WriteStepCounts = Future<void> Function(Map<String, dynamic> counts);

class StepTrackerService extends ChangeNotifier {
  final DateTime Function() _now;
  final ReadStepCounts _read;
  final WriteStepCounts _write;
  late final Future<void> _ready;
  Future<void> _pending = Future<void>.value();
  String _date = '';
  int _sensorSteps = 0;
  int _manualSteps = 0;
  int? _lastSensor;
  bool _isListening = false;
  bool _isInitializing = false;
  bool _disposed = false;
  StreamSubscription<StepCount>? _stepCountSubscription;
  Timer? _dayTicker;

  StepTrackerService({DateTime Function()? now, ReadStepCounts? readCounts, WriteStepCounts? writeCounts})
      : _now = now ?? DateTime.now,
        _read = readCounts ?? DatabaseHelper.instance.getStepCounts,
        _write = writeCounts ?? DatabaseHelper.instance.saveStepCounts {
    _ready = _loadDate();
  }

  int get todaySteps => _sensorSteps + _manualSteps;
  bool get isListening => _isListening;
  double get estimatedStepCalories => todaySteps * 0.04;

  String get _today => _now().toIso8601String().split('T').first;

  Future<void> _loadDate() async {
    final date = _today;
    final saved = await _read(date);
    _date = date;
    _lastSensor = saved?['last_sensor'] as int?;
    _sensorSteps = (saved?['sensor_steps'] as num?)?.toInt() ?? 0;
    _manualSteps = (saved?['manual_steps'] as num?)?.toInt() ?? 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _pending.then((_) async {
      await _ready;
      if (!_disposed) await action();
    });
    // Keep later events usable after a storage failure.
    _pending = result.catchError((Object error) {
      debugPrint('Could not persist step counts: $error');
    });
    return result;
  }

  Future<void> refreshDay() => _enqueue(() async {
    if (_date != _today) await _loadDate();
  });

  Future<void> _save() => _write({
    'date': _date,
    'last_sensor': _lastSensor,
    'sensor_steps': _sensorSteps,
    'manual_steps': _manualSteps,
  });

  Future<void> initializeStepCounter() async {
    if (_isListening || _isInitializing || _disposed) return;
    _isInitializing = true;
    try {
      await refreshDay();
      if (_disposed) return;
      _dayTicker ??= Timer.periodic(const Duration(minutes: 1), (_) {
        unawaited(refreshDay().catchError((Object error) {
          debugPrint('Could not refresh step date: $error');
        }));
      });
      if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) return;
      final permission = defaultTargetPlatform == TargetPlatform.iOS
          ? Permission.sensors : Permission.activityRecognition;
      if (await permission.request().isGranted && !_disposed) {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (event) => unawaited(recordSensorSteps(event.steps).catchError((Object error) {
            debugPrint('Could not save sensor steps: $error');
          })),
          onError: _onStepCountError,
        );
        _isListening = true;
        _notify();
      }
    } catch (error) {
      debugPrint('Step counter unavailable: $error');
    } finally {
      _isInitializing = false;
    }
  }

  @visibleForTesting
  Future<void> recordSensorSteps(int steps) => _enqueue(() async {
    if (steps < 0) return;
    if (_date != _today) await _loadDate();
    final last = _lastSensor;
    if (last != null) {
      // A lower counter means the device restarted.
      _sensorSteps += steps >= last ? steps - last : steps;
    }
    _lastSensor = steps;
    await _save();
    _notify();
  });

  void _onStepCountError(dynamic error) {
    debugPrint('Pedometer error: $error');
    _isListening = false;
    _notify();
  }

  Future<void> addManualSteps(int steps) => _enqueue(() async {
    if (steps <= 0) return;
    if (_date != _today) await _loadDate();
    _manualSteps += steps;
    await _save();
    _notify();
  });

  Future<void> resetCounts() => _enqueue(() async {
    if (_date != _today) await _loadDate();
    _sensorSteps = 0;
    _manualSteps = 0;
    await _save();
    _notify();
  });

  @override
  void dispose() {
    _disposed = true;
    _dayTicker?.cancel();
    _stepCountSubscription?.cancel();
    super.dispose();
  }
}
