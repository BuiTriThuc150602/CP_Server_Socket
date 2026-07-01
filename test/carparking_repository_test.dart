import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:socket_server/core/storage/json_storage_repository.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/repositories/carparking_repository.dart';

void main() {
  late Directory tempDir;
  late Directory legacyDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cp_repo_new');
    legacyDir = await Directory.systemTemp.createTemp('cp_repo_old');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await legacyDir.exists()) {
      await legacyDir.delete(recursive: true);
    }
  });

  test('migrates old device, socket server, and rows', () async {
    await File(
      '${legacyDir.path}${Platform.pathSeparator}device.json',
    ).writeAsString('''
{
  "deviceId": "DG-01",
  "deviceIp": "10.0.0.5",
  "deviceName": "Gate A",
  "devicePort": "5000"
}
''');
    await File(
      '${legacyDir.path}${Platform.pathSeparator}socket_server.json',
    ).writeAsString('{"serverIp":"0.0.0.0","serverPort":"4321"}');
    await File(
      '${legacyDir.path}${Platform.pathSeparator}socket_server_data.json',
    ).writeAsString('''
{
  "rows": [
    {"type":"card","cardId":"111","readerId":"2"},
    {"type":"io","inputName":"Aux 2"}
  ]
}
''');

    final repository = CarParkingRepository(
      storage: JsonStorageRepository(
        rootDirectory: tempDir,
        legacyDirectory: legacyDir,
      ),
    );

    final workspace = await repository.load();

    expect(workspace.devices.single.deviceId, 'DG-01');
    expect(workspace.devices.single.label, 'Gate A');
    expect(workspace.server.bindHost, '0.0.0.0');
    expect(workspace.server.port, 4321);
    expect(workspace.rows.length, 2);
    expect(workspace.rows.first.label, 'Card 1');
    expect(workspace.rows.first.readerIndex, 2);
    expect(workspace.rows.last.label, 'IO 1');
    expect(workspace.rows.last.inputIndex, 6);
    expect(
      await File(
        '${legacyDir.path}${Platform.pathSeparator}device.json',
      ).exists(),
      isTrue,
    );
  });

  test('saves and loads workspace file', () async {
    final repository = CarParkingRepository(
      storage: JsonStorageRepository(
        rootDirectory: tempDir,
        legacyDirectory: legacyDir,
      ),
    );
    final workspace = CarParkingWorkspace.defaults();

    await repository.save(workspace);
    final loaded = await repository.load();

    expect(loaded.devices.first.id, workspace.devices.first.id);
    expect(loaded.rows.length, workspace.rows.length);
  });
}
