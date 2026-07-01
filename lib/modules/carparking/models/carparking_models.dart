enum CarParkingSignalType { card, io }

enum CarParkingScenarioMode { sequential, random }

int _carParkingIdCounter = 0;

String newCarParkingId(String prefix) {
  _carParkingIdCounter++;
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_carParkingIdCounter';
}

class CarParkingDeviceProfile {
  const CarParkingDeviceProfile({
    required this.id,
    required this.label,
    required this.deviceId,
    required this.deviceIp,
    required this.devicePort,
    required this.deviceName,
    required this.manufacturer,
    required this.modelName,
    required this.protocolType,
    required this.baudRate,
    required this.comName,
    required this.readerCardFormats,
    required this.enabled,
  });

  factory CarParkingDeviceProfile.defaults() {
    return const CarParkingDeviceProfile(id: 'default_device', label: 'Default Device', deviceId: '', deviceIp: '', devicePort: '', deviceName: '', manufacturer: '', modelName: '', protocolType: 'TCP', baudRate: '', comName: '', readerCardFormats: [], enabled: true);
  }

  factory CarParkingDeviceProfile.fromJson(Map<String, dynamic> json) {
    return CarParkingDeviceProfile(
      id: (json['id'] ?? newCarParkingId('device')).toString(),
      label: (json['label'] ?? json['deviceName'] ?? 'Device').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceIp: (json['deviceIp'] ?? '').toString(),
      devicePort: (json['devicePort'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      modelName: (json['modelName'] ?? '').toString(),
      protocolType: (json['protocolType'] ?? 'TCP').toString(),
      baudRate: (json['baudRate'] ?? '').toString(),
      comName: (json['comName'] ?? '').toString(),
      readerCardFormats: _stringList(json['readerCardFormats']),
      enabled: json['enabled'] != false,
    );
  }

  final String id;
  final String label;
  final String deviceId;
  final String deviceIp;
  final String devicePort;
  final String deviceName;
  final String manufacturer;
  final String modelName;
  final String protocolType;
  final String baudRate;
  final String comName;
  final List<String> readerCardFormats;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'deviceId': deviceId,
      'deviceIp': deviceIp,
      'devicePort': devicePort,
      'deviceName': deviceName,
      'manufacturer': manufacturer,
      'modelName': modelName,
      'protocolType': protocolType,
      'baudRate': baudRate,
      'comName': comName,
      'readerCardFormats': readerCardFormats,
      'enabled': enabled,
    };
  }

  Map<String, dynamic> toCompatibleDeviceInfoJson() {
    return {'deviceId': deviceId, 'deviceIp': deviceIp, 'deviceName': deviceName, 'devicePort': devicePort, 'manufacturer': manufacturer, 'modelName': modelName, 'protocolType': protocolType, 'baudRate': baudRate, 'comName': comName};
  }

  CarParkingDeviceProfile copyWith({String? id, String? label, String? deviceId, String? deviceIp, String? devicePort, String? deviceName, String? manufacturer, String? modelName, String? protocolType, String? baudRate, String? comName, List<String>? readerCardFormats, bool? enabled}) {
    return CarParkingDeviceProfile(
      id: id ?? this.id,
      label: label ?? this.label,
      deviceId: deviceId ?? this.deviceId,
      deviceIp: deviceIp ?? this.deviceIp,
      devicePort: devicePort ?? this.devicePort,
      deviceName: deviceName ?? this.deviceName,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      protocolType: protocolType ?? this.protocolType,
      baudRate: baudRate ?? this.baudRate,
      comName: comName ?? this.comName,
      readerCardFormats: readerCardFormats ?? this.readerCardFormats,
      enabled: enabled ?? this.enabled,
    );
  }
}

class CarParkingServerProfile {
  const CarParkingServerProfile({required this.bindHost, required this.port, required this.autoStart, required this.heartbeatEnabled, required this.heartbeatIntervalSeconds});

  factory CarParkingServerProfile.defaults() {
    return const CarParkingServerProfile(bindHost: '127.0.0.1', port: 1234, autoStart: true, heartbeatEnabled: true, heartbeatIntervalSeconds: 3);
  }

  factory CarParkingServerProfile.fromJson(Map<String, dynamic> json) {
    return CarParkingServerProfile(
      bindHost: (json['bindHost'] ?? json['serverIp'] ?? '127.0.0.1').toString(),
      port: _intValue(json['port'] ?? json['serverPort'], 1234),
      autoStart: json['autoStart'] != false,
      heartbeatEnabled: json['heartbeatEnabled'] != false,
      heartbeatIntervalSeconds: _intValue(json['heartbeatIntervalSeconds'], 3).clamp(1, 3600),
    );
  }

  final String bindHost;
  final int port;
  final bool autoStart;
  final bool heartbeatEnabled;
  final int heartbeatIntervalSeconds;

  Map<String, dynamic> toJson() {
    return {'bindHost': bindHost, 'port': port, 'autoStart': autoStart, 'heartbeatEnabled': heartbeatEnabled, 'heartbeatIntervalSeconds': heartbeatIntervalSeconds};
  }

  CarParkingServerProfile copyWith({String? bindHost, int? port, bool? autoStart, bool? heartbeatEnabled, int? heartbeatIntervalSeconds}) {
    return CarParkingServerProfile(bindHost: bindHost ?? this.bindHost, port: port ?? this.port, autoStart: autoStart ?? this.autoStart, heartbeatEnabled: heartbeatEnabled ?? this.heartbeatEnabled, heartbeatIntervalSeconds: heartbeatIntervalSeconds ?? this.heartbeatIntervalSeconds);
  }
}

class CarParkingSignalRow {
  const CarParkingSignalRow({
    required this.id,
    required this.label,
    required this.enabled,
    required this.type,
    required this.deviceProfileId,
    required this.cardId,
    required this.readerIndex,
    required this.readerName,
    required this.inputIndex,
    required this.inputName,
    required this.delayMs,
    required this.note,
  });

  factory CarParkingSignalRow.card({required String deviceProfileId, String? label}) {
    return CarParkingSignalRow(id: newCarParkingId('row'), label: label ?? 'Card', enabled: true, type: CarParkingSignalType.card, deviceProfileId: deviceProfileId, cardId: '', readerIndex: 1, readerName: 'Reader 1', inputIndex: 1, inputName: 'Button 1', delayMs: 1000, note: '');
  }

  factory CarParkingSignalRow.io({required String deviceProfileId, String? label}) {
    return CarParkingSignalRow(id: newCarParkingId('row'), label: label ?? 'IO', enabled: true, type: CarParkingSignalType.io, deviceProfileId: deviceProfileId, cardId: '', readerIndex: 1, readerName: 'Reader 1', inputIndex: 1, inputName: 'Button 1', delayMs: 1000, note: '');
  }

  factory CarParkingSignalRow.fromJson(Map<String, dynamic> json) {
    final type = _signalType(json['type']);
    return CarParkingSignalRow(
      id: _idValue(json['id'], 'row'),
      label: (json['label'] ?? '').toString(),
      enabled: json['enabled'] != false,
      type: type,
      deviceProfileId: (json['deviceProfileId'] ?? '').toString(),
      cardId: (json['cardId'] ?? json['cardNumber'] ?? '').toString(),
      readerIndex: _intValue(json['readerIndex'] ?? json['readerId'], 1),
      readerName: (json['readerName'] ?? '').toString(),
      inputIndex: _intValue(json['inputIndex'], 1),
      inputName: (json['inputName'] ?? json['selectedInputName'] ?? 'Button 1').toString(),
      delayMs: _intValue(json['delayMs'], 1000),
      note: (json['note'] ?? '').toString(),
    ).withDefaultsForType(type);
  }

  final String id;
  final String label;
  final bool enabled;
  final CarParkingSignalType type;
  final String deviceProfileId;
  final String cardId;
  final int readerIndex;
  final String readerName;
  final int inputIndex;
  final String inputName;
  final int delayMs;
  final String note;

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'enabled': enabled, 'type': type.name, 'deviceProfileId': deviceProfileId, 'cardId': cardId, 'readerIndex': readerIndex, 'readerName': readerName, 'inputIndex': inputIndex, 'inputName': inputName, 'delayMs': delayMs, 'note': note};
  }

  CarParkingSignalRow withDefaultsForType(CarParkingSignalType type) {
    final normalizedReaderName = readerName.isEmpty ? 'Reader $readerIndex' : readerName;
    final normalizedLabel = label.isEmpty ? (type == CarParkingSignalType.card ? 'Card' : 'IO') : label;
    return copyWith(type: type, label: normalizedLabel, readerName: normalizedReaderName, inputIndex: inputIndex.clamp(1, 8), delayMs: delayMs < 0 ? 0 : delayMs);
  }

  CarParkingSignalRow copyWith({String? id, String? label, bool? enabled, CarParkingSignalType? type, String? deviceProfileId, String? cardId, int? readerIndex, String? readerName, int? inputIndex, String? inputName, int? delayMs, String? note}) {
    return CarParkingSignalRow(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      deviceProfileId: deviceProfileId ?? this.deviceProfileId,
      cardId: cardId ?? this.cardId,
      readerIndex: readerIndex ?? this.readerIndex,
      readerName: readerName ?? this.readerName,
      inputIndex: inputIndex ?? this.inputIndex,
      inputName: inputName ?? this.inputName,
      delayMs: delayMs ?? this.delayMs,
      note: note ?? this.note,
    );
  }
}

class CarParkingScenario {
  const CarParkingScenario({required this.id, required this.name, required this.stepRowIds, required this.loopCount, required this.defaultDelayMs, required this.mode, required this.stopOnError});

  factory CarParkingScenario.defaults() {
    return const CarParkingScenario(id: 'default_scenario', name: 'Enabled rows', stepRowIds: [], loopCount: 1, defaultDelayMs: 1000, mode: CarParkingScenarioMode.sequential, stopOnError: false);
  }

  factory CarParkingScenario.fromJson(Map<String, dynamic> json) {
    return CarParkingScenario(
      id: (json['id'] ?? newCarParkingId('scenario')).toString(),
      name: (json['name'] ?? 'Scenario').toString(),
      stepRowIds: _stringList(json['stepRowIds']),
      loopCount: _intValue(json['loopCount'], 1),
      defaultDelayMs: _intValue(json['defaultDelayMs'], 1000),
      mode: _scenarioMode(json['mode']),
      stopOnError: json['stopOnError'] == true,
    );
  }

  final String id;
  final String name;
  final List<String> stepRowIds;
  final int loopCount;
  final int defaultDelayMs;
  final CarParkingScenarioMode mode;
  final bool stopOnError;

  bool get isInfinite => loopCount <= 0;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'stepRowIds': stepRowIds, 'loopCount': loopCount, 'defaultDelayMs': defaultDelayMs, 'mode': mode.name, 'stopOnError': stopOnError};
  }

  CarParkingScenario copyWith({String? id, String? name, List<String>? stepRowIds, int? loopCount, int? defaultDelayMs, CarParkingScenarioMode? mode, bool? stopOnError}) {
    return CarParkingScenario(id: id ?? this.id, name: name ?? this.name, stepRowIds: stepRowIds ?? this.stepRowIds, loopCount: loopCount ?? this.loopCount, defaultDelayMs: defaultDelayMs ?? this.defaultDelayMs, mode: mode ?? this.mode, stopOnError: stopOnError ?? this.stopOnError);
  }
}

class CarParkingWorkspace {
  const CarParkingWorkspace({required this.devices, required this.server, required this.rows, required this.scenarios, required this.defaultDeviceProfileId});

  factory CarParkingWorkspace.defaults() {
    final device = CarParkingDeviceProfile.defaults();
    return CarParkingWorkspace(devices: [device], server: CarParkingServerProfile.defaults(), rows: List.generate(4, (index) => CarParkingSignalRow.card(deviceProfileId: device.id, label: 'Card ${index + 1}')), scenarios: [CarParkingScenario.defaults()], defaultDeviceProfileId: device.id);
  }

  factory CarParkingWorkspace.fromJson(Map<String, dynamic> json) {
    final devices = _mapList(json['devices']).map(CarParkingDeviceProfile.fromJson).toList();
    final safeDevices = devices.isEmpty ? [CarParkingDeviceProfile.defaults()] : devices;
    final defaultDeviceId = (json['defaultDeviceProfileId'] ?? safeDevices.first.id).toString();
    final rows = _mapList(json['rows']).map(CarParkingSignalRow.fromJson).map((row) => row.deviceProfileId.isEmpty ? row.copyWith(deviceProfileId: defaultDeviceId) : row).toList();
    final normalizedRows = _uniqueSignalRows(rows);
    return CarParkingWorkspace(
      devices: safeDevices,
      server: CarParkingServerProfile.fromJson(_mapValue(json['server']) ?? const {}),
      rows: normalizedRows.isEmpty ? [CarParkingSignalRow.card(deviceProfileId: defaultDeviceId, label: 'Card 1')] : normalizedRows,
      scenarios: _mapList(json['scenarios']).map(CarParkingScenario.fromJson).toList(),
      defaultDeviceProfileId: defaultDeviceId,
    );
  }

  final List<CarParkingDeviceProfile> devices;
  final CarParkingServerProfile server;
  final List<CarParkingSignalRow> rows;
  final List<CarParkingScenario> scenarios;
  final String defaultDeviceProfileId;

  Map<String, dynamic> toJson() {
    return {
      'version': 2,
      'defaultDeviceProfileId': defaultDeviceProfileId,
      'server': server.toJson(),
      'devices': devices.map((device) => device.toJson()).toList(),
      'rows': rows.map((row) => row.toJson()).toList(),
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
      'lastSaved': DateTime.now().toIso8601String(),
    };
  }

  CarParkingWorkspace copyWith({List<CarParkingDeviceProfile>? devices, CarParkingServerProfile? server, List<CarParkingSignalRow>? rows, List<CarParkingScenario>? scenarios, String? defaultDeviceProfileId}) {
    return CarParkingWorkspace(devices: devices ?? this.devices, server: server ?? this.server, rows: rows ?? this.rows, scenarios: scenarios ?? this.scenarios, defaultDeviceProfileId: defaultDeviceProfileId ?? this.defaultDeviceProfileId);
  }
}

List<CarParkingSignalRow> normalizeCarParkingSignalRowIds(List<CarParkingSignalRow> rows) {
  return _uniqueSignalRows(rows);
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((item) => item.trim()).toList();
  }
  return const [];
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

int _intValue(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _idValue(Object? value, String prefix) {
  final id = value?.toString().trim() ?? '';
  return id.isEmpty ? newCarParkingId(prefix) : id;
}

List<CarParkingSignalRow> _uniqueSignalRows(List<CarParkingSignalRow> rows) {
  final seen = <String>{};
  final normalized = <CarParkingSignalRow>[];
  for (final row in rows) {
    var id = row.id.trim();
    while (id.isEmpty || seen.contains(id)) {
      id = newCarParkingId('row');
    }
    seen.add(id);
    normalized.add(id == row.id ? row : row.copyWith(id: id));
  }
  return normalized;
}

CarParkingSignalType _signalType(Object? value) {
  final text = value?.toString().toLowerCase() ?? '';
  return text.contains('io') ? CarParkingSignalType.io : CarParkingSignalType.card;
}

CarParkingScenarioMode _scenarioMode(Object? value) {
  final text = value?.toString().toLowerCase() ?? '';
  return text.contains('random') ? CarParkingScenarioMode.random : CarParkingScenarioMode.sequential;
}
