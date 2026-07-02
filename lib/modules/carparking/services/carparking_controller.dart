import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_server/core/logging/logger_service.dart';
import 'package:socket_server/core/socket/tcp_server_engine.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/repositories/carparking_repository.dart';
import 'package:socket_server/modules/carparking/services/carparking_payload_factory.dart';
import 'package:socket_server/modules/carparking/services/carparking_scenario_runner.dart';

enum ConsoleEntryKind { incoming, outgoing, error, info }

class ConsoleEntry {
  const ConsoleEntry({
    required this.kind,
    required this.text,
    required this.timestamp,
    this.sessionId,
  });

  final ConsoleEntryKind kind;
  final String text;
  final DateTime timestamp;
  final String? sessionId;

  bool get looksLikeJson {
    final trimmed = text.trim();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  String get prettyText {
    if (!looksLikeJson) {
      return text;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } catch (_) {
      return text;
    }
  }
}

class CarParkingController extends ChangeNotifier {
  CarParkingController({
    CarParkingRepository? repository,
    TcpServerEngine? engine,
    CarParkingPayloadFactory? payloadFactory,
    CarParkingScenarioRunner? scenarioRunner,
    LoggerService? logger,
  }) : _repository = repository ?? CarParkingRepository(),
       _engine = engine ?? TcpServerEngine(),
       _payloadFactory = payloadFactory ?? const CarParkingPayloadFactory(),
       _scenarioRunner = scenarioRunner ?? CarParkingScenarioRunner(),
       _logger = logger ?? LoggerService.instance;

  final CarParkingRepository _repository;
  final TcpServerEngine _engine;
  final CarParkingPayloadFactory _payloadFactory;
  final CarParkingScenarioRunner _scenarioRunner;
  final LoggerService _logger;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _saveDebounce;
  Timer? _heartbeatTimer;

  CarParkingWorkspace _workspace = CarParkingWorkspace.defaults();
  bool _initialized = false;
  bool _loading = false;
  String? _warning;
  String? _serverError;
  bool _prettyConsole = false;
  List<TcpClientSession> _clients = const [];
  TcpServerState _serverState = TcpServerState.stopped;
  ScenarioRunnerSnapshot _runnerSnapshot = ScenarioRunnerSnapshot.stopped;
  final List<ConsoleEntry> _console = [];
  ConsoleEntry? _lastConsoleEntry;

  CarParkingWorkspace get workspace => _workspace;
  List<CarParkingDeviceProfile> get devices => _workspace.devices;
  CarParkingServerProfile get server => _workspace.server;
  List<CarParkingSignalRow> get rows => _workspace.rows;
  List<TcpClientSession> get clients => _clients;
  TcpServerState get serverState => _serverState;
  ScenarioRunnerSnapshot get runnerSnapshot => _runnerSnapshot;
  List<ConsoleEntry> get console => List.unmodifiable(_console);
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get warning => _warning;
  String? get serverError => _serverError;
  bool get prettyConsole => _prettyConsole;
  bool get autoTestRunning =>
      _runnerSnapshot.status != ScenarioRunnerStatus.stopped;

  Future<void> initialize() async {
    if (_initialized || _loading) {
      return;
    }
    _loading = true;
    notifyListeners();

    _workspace = _withUniqueRowIds(await _repository.load());
    unawaited(_repository.save(_workspace));
    _serverState = _engine.state;
    _subscriptions.addAll([
      _engine.stateStream.listen((state) {
        _serverState = state;
        notifyListeners();
      }),
      _engine.clientsStream.listen((clients) {
        _clients = clients;
        notifyListeners();
      }),
      _engine.incomingMessages.listen((message) {
        _addConsole(
          ConsoleEntry(
            kind: ConsoleEntryKind.incoming,
            text: message.text,
            timestamp: message.timestamp,
            sessionId: message.sessionId,
          ),
        );
      }),
      _engine.outgoingMessages.listen((message) {
        _addConsole(
          ConsoleEntry(
            kind: ConsoleEntryKind.outgoing,
            text: message.text,
            timestamp: message.timestamp,
            sessionId: message.sessionId,
          ),
        );
      }),
      _engine.errors.listen((error) {
        _serverError = error.toString();
        _addConsole(
          ConsoleEntry(
            kind: ConsoleEntryKind.error,
            text: error.toString(),
            timestamp: DateTime.now(),
          ),
        );
      }),
      _scenarioRunner.snapshots.listen((snapshot) {
        _runnerSnapshot = snapshot;
        notifyListeners();
      }),
    ]);

    _initialized = true;
    _loading = false;
    notifyListeners();

    if (server.autoStart) {
      unawaited(startServer());
    }
    _configureHeartbeat();
  }

  Future<void> startServer() async {
    _serverError = null;
    try {
      await _engine.start(host: server.bindHost, port: server.port);
    } catch (error) {
      _serverError =
          'Could not start ${server.bindHost}:${server.port}: $error';
      notifyListeners();
    }
  }

  Future<void> stopServer() => _engine.stop();

  Future<void> restartServer() async {
    _serverError = null;
    try {
      await _engine.restart(host: server.bindHost, port: server.port);
    } catch (error) {
      _serverError =
          'Could not restart ${server.bindHost}:${server.port}: $error';
      notifyListeners();
    }
  }

  void updateServer(CarParkingServerProfile serverProfile) {
    _workspace = _workspace.copyWith(server: serverProfile);
    _configureHeartbeat();
    _scheduleSave();
    notifyListeners();
  }

  Future<void> applyServerAndRestart(
    CarParkingServerProfile serverProfile,
  ) async {
    updateServer(serverProfile);
    await _repository.save(_workspace);
    await restartServer();
  }

  void addDevice() {
    final device = CarParkingDeviceProfile.defaults().copyWith(
      id: newCarParkingId('device'),
      label: 'Device ${devices.length + 1}',
    );
    addDeviceProfile(device);
  }

  void addDeviceProfile(CarParkingDeviceProfile device) {
    _workspace = _workspace.copyWith(devices: [...devices, device]);
    _scheduleSave();
    notifyListeners();
  }

  void duplicateDevice(CarParkingDeviceProfile source) {
    final copy = source.copyWith(
      id: newCarParkingId('device'),
      label: '${source.label} Copy',
    );
    _workspace = _workspace.copyWith(devices: [...devices, copy]);
    _scheduleSave();
    notifyListeners();
  }

  void deleteDevice(String id) {
    if (devices.length <= 1) {
      _warning = 'At least one device profile is required.';
      notifyListeners();
      return;
    }
    final remaining = devices.where((device) => device.id != id).toList();
    final fallbackId = remaining.first.id;
    _workspace = _workspace.copyWith(
      devices: remaining,
      defaultDeviceProfileId:
          _workspace.defaultDeviceProfileId == id ? fallbackId : null,
      rows:
          rows
              .map(
                (row) =>
                    row.deviceProfileId == id
                        ? row.copyWith(deviceProfileId: fallbackId)
                        : row,
              )
              .toList(),
    );
    _scheduleSave();
    notifyListeners();
  }

  void updateDevice(CarParkingDeviceProfile device) {
    _workspace = _workspace.copyWith(
      devices: [
        for (final current in devices)
          if (current.id == device.id) device else current,
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void setDefaultDevice(String id) {
    _workspace = _workspace.copyWith(defaultDeviceProfileId: id);
    _scheduleSave();
    notifyListeners();
  }

  void addCardRow() {
    _workspace = _workspace.copyWith(
      rows: [
        ...rows,
        CarParkingSignalRow.card(
          deviceProfileId: _workspace.defaultDeviceProfileId,
          label:
              'Card ${rows.where((row) => row.type == CarParkingSignalType.card).length + 1}',
        ),
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void addIoRow() {
    _workspace = _workspace.copyWith(
      rows: [
        ...rows,
        CarParkingSignalRow.io(
          deviceProfileId: _workspace.defaultDeviceProfileId,
          label:
              'IO ${rows.where((row) => row.type == CarParkingSignalType.io).length + 1}',
        ),
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void updateRow(CarParkingSignalRow row) {
    _workspace = _workspace.copyWith(
      rows: [
        for (final current in rows)
          if (current.id == row.id) row else current,
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void duplicateRow(CarParkingSignalRow row) {
    _workspace = _workspace.copyWith(
      rows: [
        ...rows,
        row.copyWith(id: newCarParkingId('row'), label: '${row.label} Copy'),
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void deleteRow(String id) {
    _workspace = _workspace.copyWith(
      rows: rows.where((row) => row.id != id).toList(),
    );
    _scheduleSave();
    notifyListeners();
  }

  String exportRowsJson() {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(rows.map((row) => row.toJson()).toList());
  }

  String exportSelectedRowsJson(Set<String> rowIds) {
    return const JsonEncoder.withIndent('  ').convert(
      rows
          .where((row) => rowIds.contains(row.id))
          .map((row) => row.toJson())
          .toList(),
    );
  }

  void importRowsJson(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array of rows.');
    }
    final imported =
        decoded
            .whereType<Map>()
            .map(
              (item) =>
                  CarParkingSignalRow.fromJson(Map<String, dynamic>.from(item)),
            )
            .map(
              (row) =>
                  row.deviceProfileId.isEmpty
                      ? row.copyWith(
                        deviceProfileId: _workspace.defaultDeviceProfileId,
                      )
                      : row,
            )
            .map((row) => row.copyWith(id: newCarParkingId('row')))
            .toList();
    _workspace = _workspace.copyWith(
      rows: normalizeCarParkingSignalRowIds([...rows, ...imported]),
    );
    _scheduleSave();
    notifyListeners();
  }

  void duplicateRows(Iterable<String> rowIds) {
    final selected = rows.where((row) => rowIds.contains(row.id)).toList();
    if (selected.isEmpty) {
      return;
    }
    _workspace = _workspace.copyWith(
      rows: [
        ...rows,
        for (final row in selected)
          row.copyWith(id: newCarParkingId('row'), label: '${row.label} Copy'),
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  void deleteRows(Iterable<String> rowIds) {
    final ids = rowIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    _workspace = _workspace.copyWith(
      rows: rows.where((row) => !ids.contains(row.id)).toList(),
    );
    _scheduleSave();
    notifyListeners();
  }

  void setRowsEnabled(Iterable<String> rowIds, bool enabled) {
    final ids = rowIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    _workspace = _workspace.copyWith(
      rows: [
        for (final row in rows)
          if (ids.contains(row.id)) row.copyWith(enabled: enabled) else row,
      ],
    );
    _scheduleSave();
    notifyListeners();
  }

  Future<void> sendRowsOnce(Iterable<String> rowIds) async {
    final ids = rowIds.toSet();
    for (final row in rows.where(
      (row) => ids.contains(row.id) && row.enabled,
    )) {
      await sendRow(row);
    }
  }

  Future<void> sendRow(CarParkingSignalRow row) async {
    final device = _deviceForRow(row);
    if (device == null || device.deviceId.isEmpty) {
      _warning =
          'Configure a device profile before sending CarParking payloads.';
      _addConsole(
        ConsoleEntry(
          kind: ConsoleEntryKind.error,
          text: _warning!,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    final payload =
        row.type == CarParkingSignalType.card
            ? _payloadFactory.cardLog(device: device, row: row)
            : _payloadFactory.ioStatus(device: device, row: row);
    if (_clients.isEmpty) {
      _addConsole(
        ConsoleEntry(
          kind: ConsoleEntryKind.info,
          text:
              'No TCP clients connected. Payload generated but not delivered.',
          timestamp: DateTime.now(),
        ),
      );
    }
    await _engine.sendToAll(
      _payloadFactory.encodeLine(payload),
      appendNewline: true,
    );
    _warning = null;
    notifyListeners();
  }

  String previewPayloadForRow(CarParkingSignalRow row) {
    final device = _deviceForRow(row) ?? _defaultEnabledDevice();
    if (device == null) {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert({'error': 'No device profile configured'});
    }
    final payload =
        row.type == CarParkingSignalType.card
            ? _payloadFactory.cardLog(device: device, row: row)
            : _payloadFactory.ioStatus(device: device, row: row);
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> sendHeartbeat() async {
    final device = _defaultEnabledDevice();
    if (device == null || device.deviceId.isEmpty) {
      _warning = 'Heartbeat is waiting for a configured device profile.';
      notifyListeners();
      return;
    }
    _warning = null;
    await _engine.sendToAll(
      _payloadFactory.encodeLine(_payloadFactory.connectStatus(device)),
      appendNewline: true,
    );
  }

  Future<void> startScenario({List<String>? selectedRowIds}) async {
    final scenario =
        _workspace.scenarios.isEmpty
            ? CarParkingScenario.defaults()
            : _workspace.scenarios.first;
    final selected =
        selectedRowIds == null || selectedRowIds.isEmpty
            ? rows
            : rows.where((row) => selectedRowIds.contains(row.id)).toList();
    await _scenarioRunner.start(
      rows: selected,
      scenario: scenario,
      sender: sendRow,
    );
  }

  void pauseScenario() => _scenarioRunner.pause();

  void resumeScenario() => _scenarioRunner.resume();

  void stopScenario() => _scenarioRunner.stop();

  void updateScenario(CarParkingScenario scenario) {
    final scenarios =
        _workspace.scenarios.isEmpty
            ? [scenario]
            : [scenario, ..._workspace.scenarios.skip(1)];
    _workspace = _workspace.copyWith(scenarios: scenarios);
    _scheduleSave();
    notifyListeners();
  }

  void clearConsole() {
    _console.clear();
    notifyListeners();
  }

  void setPrettyConsole(bool value) {
    _prettyConsole = value;
    notifyListeners();
  }

  Future<void> saveNow() async {
    _saveDebounce?.cancel();
    await _repository.save(_workspace);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _heartbeatTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_scenarioRunner.dispose());
    unawaited(_engine.dispose());
    unawaited(_repository.save(_workspace));
    super.dispose();
  }

  CarParkingDeviceProfile? _deviceForRow(CarParkingSignalRow row) {
    return devices
        .where((device) => device.id == row.deviceProfileId)
        .firstOrNull;
  }

  CarParkingDeviceProfile? _defaultEnabledDevice() {
    return devices
            .where((device) => device.id == _workspace.defaultDeviceProfileId)
            .firstOrNull ??
        devices.where((device) => device.enabled).firstOrNull;
  }

  void _configureHeartbeat() {
    _heartbeatTimer?.cancel();
    if (!server.heartbeatEnabled) {
      return;
    }
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: server.heartbeatIntervalSeconds),
      (_) => unawaited(sendHeartbeat()),
    );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_repository.save(_workspace));
      unawaited(_logger.info('CarParking workspace saved'));
    });
  }

  void _addConsole(ConsoleEntry entry) {
    if (_isDuplicateConsoleEntry(entry)) {
      return;
    }
    _console.insert(0, entry);
    if (_console.length > 500) {
      _console.removeRange(500, _console.length);
    }
    notifyListeners();
  }

  bool _isDuplicateConsoleEntry(ConsoleEntry entry) {
    final last = _lastConsoleEntry;
    _lastConsoleEntry = entry;
    if (last == null) {
      return false;
    }
    // The TCP engine reports runtime errors through its stream and also throws
    // to callers. This tiny window removes only that callback-path duplicate.
    return entry.kind == last.kind &&
        entry.sessionId == last.sessionId &&
        entry.text == last.text &&
        entry.timestamp.difference(last.timestamp).abs() <=
            const Duration(milliseconds: 300);
  }

  CarParkingWorkspace _withUniqueRowIds(CarParkingWorkspace workspace) {
    return workspace.copyWith(
      rows: normalizeCarParkingSignalRowIds(workspace.rows),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
