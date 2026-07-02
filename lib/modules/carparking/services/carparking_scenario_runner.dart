import 'dart:async';
import 'dart:math';

import 'package:socket_server/modules/carparking/models/carparking_models.dart';

enum ScenarioRunnerStatus { stopped, running, paused }

class ScenarioRunnerSnapshot {
  const ScenarioRunnerSnapshot({
    required this.status,
    required this.currentStepIndex,
    required this.completedLoops,
    required this.totalSteps,
    this.currentRowId,
    this.lastError,
  });

  final ScenarioRunnerStatus status;
  final int currentStepIndex;
  final int completedLoops;
  final int totalSteps;
  final String? currentRowId;
  final Object? lastError;

  static const stopped = ScenarioRunnerSnapshot(
    status: ScenarioRunnerStatus.stopped,
    currentStepIndex: 0,
    completedLoops: 0,
    totalSteps: 0,
  );

  ScenarioRunnerSnapshot copyWith({
    ScenarioRunnerStatus? status,
    int? currentStepIndex,
    int? completedLoops,
    int? totalSteps,
    String? currentRowId,
    Object? lastError,
  }) {
    return ScenarioRunnerSnapshot(
      status: status ?? this.status,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedLoops: completedLoops ?? this.completedLoops,
      totalSteps: totalSteps ?? this.totalSteps,
      currentRowId: currentRowId ?? this.currentRowId,
      lastError: lastError ?? this.lastError,
    );
  }
}

typedef ScenarioStepSender = Future<void> Function(CarParkingSignalRow row);

class CarParkingScenarioRunner {
  CarParkingScenarioRunner({Random? random}) : _random = random ?? Random();

  final Random _random;
  Timer? _timer;
  ScenarioRunnerSnapshot _snapshot = ScenarioRunnerSnapshot.stopped;
  List<CarParkingSignalRow> _steps = const [];
  CarParkingScenario _scenario = CarParkingScenario.defaults();
  ScenarioStepSender? _sender;
  int _nextIndex = 0;

  final _snapshotController =
      StreamController<ScenarioRunnerSnapshot>.broadcast();

  ScenarioRunnerSnapshot get snapshot => _snapshot;

  Stream<ScenarioRunnerSnapshot> get snapshots => _snapshotController.stream;

  bool get isRunning => _snapshot.status == ScenarioRunnerStatus.running;

  bool get isPaused => _snapshot.status == ScenarioRunnerStatus.paused;

  Future<void> start({
    required List<CarParkingSignalRow> rows,
    required CarParkingScenario scenario,
    required ScenarioStepSender sender,
  }) async {
    stop();
    _steps = rows.where((row) => row.enabled).toList();
    _scenario = scenario;
    _sender = sender;
    _nextIndex = 0;

    if (_steps.isEmpty) {
      _emit(ScenarioRunnerSnapshot.stopped);
      return;
    }

    _emit(
      ScenarioRunnerSnapshot(
        status: ScenarioRunnerStatus.running,
        currentStepIndex: 0,
        completedLoops: 0,
        totalSteps: _steps.length,
      ),
    );
    await _runNext();
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _emit(_snapshot.copyWith(status: ScenarioRunnerStatus.paused));
  }

  void resume() {
    if (!isPaused) {
      return;
    }
    _emit(_snapshot.copyWith(status: ScenarioRunnerStatus.running));
    _scheduleNext(_scenario.defaultDelayMs);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _steps = const [];
    _sender = null;
    _nextIndex = 0;
    _emit(ScenarioRunnerSnapshot.stopped);
  }

  Future<void> dispose() async {
    stop();
    await _snapshotController.close();
  }

  Future<void> _runNext() async {
    if (!isRunning || _steps.isEmpty) {
      return;
    }

    final index = _selectIndex();
    final row = _steps[index];
    _emit(
      _snapshot.copyWith(
        currentStepIndex: index,
        totalSteps: _steps.length,
        currentRowId: row.id,
      ),
    );

    try {
      await _sender?.call(row);
    } catch (error) {
      _emit(_snapshot.copyWith(lastError: error));
      if (_scenario.stopOnError) {
        stop();
        return;
      }
    }

    final finishedLoop =
        _scenario.mode == CarParkingScenarioMode.sequential &&
        _nextIndex >= _steps.length;
    if (finishedLoop) {
      _nextIndex = 0;
      final completedLoops = _snapshot.completedLoops + 1;
      _emit(_snapshot.copyWith(completedLoops: completedLoops));
      if (!_scenario.isInfinite && completedLoops >= _scenario.loopCount) {
        stop();
        return;
      }
    }

    final delay = row.delayMs > 0 ? row.delayMs : _scenario.defaultDelayMs;
    _scheduleNext(delay);
  }

  int _selectIndex() {
    if (_scenario.mode == CarParkingScenarioMode.random) {
      return _random.nextInt(_steps.length);
    }
    final index = _nextIndex;
    _nextIndex++;
    return index.clamp(0, _steps.length - 1);
  }

  void _scheduleNext(int delayMs) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delayMs.clamp(0, 86400000)), () {
      unawaited(_runNext());
    });
  }

  void _emit(ScenarioRunnerSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }
}
