import 'package:fluxlab/core/storage/json_storage_repository.dart';
import 'package:fluxlab/modules/carparking/models/carparking_models.dart';
import 'package:fluxlab/modules/carparking/services/carparking_payload_factory.dart';

class CarParkingRepository {
  CarParkingRepository({JsonStorageRepository? storage})
    : _storage = storage ?? JsonStorageRepository();

  static const workspaceFile = 'carparking_workspace.json';
  static const oldRowsFile = 'socket_server_data.json';
  static const oldDeviceFile = 'device.json';
  static const oldServerFile = 'socket_server.json';

  final JsonStorageRepository _storage;

  Future<CarParkingWorkspace> load() async {
    final existing = await _storage.readMap(workspaceFile);
    if (existing != null) {
      return CarParkingWorkspace.fromJson(existing);
    }
    final migrated = await migrateOldData();
    await save(migrated);
    return migrated;
  }

  Future<void> save(CarParkingWorkspace workspace) {
    return _storage.writeMap(workspaceFile, workspace.toJson());
  }

  Future<CarParkingWorkspace> migrateOldData() async {
    final oldRows =
        await _storage.readLegacyMap(oldRowsFile) ??
        await _storage.readMap(oldRowsFile);
    final oldDevice =
        await _storage.readLegacyMap(oldDeviceFile) ??
        await _storage.readMap(oldDeviceFile);
    final oldServer =
        await _storage.readLegacyMap(oldServerFile) ??
        await _storage.readMap(oldServerFile);

    final defaultWorkspace = CarParkingWorkspace.defaults();
    final device =
        oldDevice == null
            ? defaultWorkspace.devices.first
            : CarParkingDeviceProfile.fromJson({
              ...oldDevice,
              'id': 'default_device',
              'label': _deviceLabel(oldDevice),
              'enabled': true,
            });

    final rows = _migrateRows(oldRows, device.id);
    final server =
        oldServer == null
            ? defaultWorkspace.server
            : CarParkingServerProfile.fromJson(oldServer);

    return CarParkingWorkspace(
      devices: [device],
      server: server,
      rows: rows.isEmpty ? defaultWorkspace.rows : rows,
      scenarios: [CarParkingScenario.defaults()],
      defaultDeviceProfileId: device.id,
    );
  }

  List<CarParkingSignalRow> _migrateRows(
    Map<String, dynamic>? oldRows,
    String deviceId,
  ) {
    final rawRows = oldRows?['rows'];
    if (rawRows is! List) {
      return const [];
    }

    var cardCount = 0;
    var ioCount = 0;
    final rows = <CarParkingSignalRow>[];
    for (final rawRow in rawRows) {
      if (rawRow is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(rawRow);
      final typeText = map['type']?.toString().toLowerCase() ?? 'card';
      final isIo = typeText.contains('io');
      if (isIo) {
        ioCount++;
      } else {
        cardCount++;
      }

      final inputName =
          (map['inputName'] ?? map['selectedInputName'] ?? 'Button 1')
              .toString();
      final inputIndex = CarParkingConstants.inputNames.indexOf(inputName) + 1;
      final label = (map['label'] ?? '').toString().trim();

      final migrated = CarParkingSignalRow.fromJson({
        ...map,
        'id': map['id'] ?? newCarParkingId('row'),
        'label':
            label.isEmpty ? (isIo ? 'IO $ioCount' : 'Card $cardCount') : label,
        'type': isIo ? 'io' : 'card',
        'deviceProfileId': map['deviceProfileId'] ?? deviceId,
        'cardId': map['cardId'] ?? map['cardNumber'] ?? '',
        'readerIndex': map['readerIndex'] ?? map['readerId'] ?? map['reader'],
        'readerName': map['readerName'],
        'inputName': inputName,
        'inputIndex': inputIndex <= 0 ? 1 : inputIndex,
      });
      rows.add(migrated);
    }
    return rows;
  }

  static String _deviceLabel(Map<String, dynamic> json) {
    final name = (json['deviceName'] ?? '').toString().trim();
    if (name.isNotEmpty) {
      return name;
    }
    final id = (json['deviceId'] ?? '').toString().trim();
    return id.isEmpty ? 'Default Device' : id;
  }
}
