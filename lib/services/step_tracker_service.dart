import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackerService extends ChangeNotifier {
  int _todaySteps = 4250; // Initial default for emulator / demo
  bool _isListening = false;
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _initialStepOffset = -1;

  int get todaySteps => _todaySteps;
  bool get isListening => _isListening;

  /// Estimated calories burned based on step count (approx 0.04 kcal / step)
  double get estimatedStepCalories => _todaySteps * 0.04;

  void initializeStepCounter() async {
    if (kIsWeb) return;

    try {
      if (await Permission.activityRecognition.request().isGranted) {
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          _onStepCount,
          onError: _onStepCountError,
          cancelOnError: false,
        );
        _isListening = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Step Counter Hardware Sensor not available: $e");
    }
  }

  void _onStepCount(StepCount event) {
    if (_initialStepOffset == -1) {
      _initialStepOffset = event.steps;
    }
    _todaySteps = event.steps - _initialStepOffset;
    if (_todaySteps < 0) _todaySteps = event.steps;
    notifyListeners();
  }

  void _onStepCountError(error) {
    debugPrint("Pedometer error: $error");
    _isListening = false;
    notifyListeners();
  }

  /// Manual step logging for emulators or custom user inputs
  void addManualSteps(int steps) {
    _todaySteps += steps;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }
}
