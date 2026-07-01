import 'package:flutter_test/flutter_test.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_payload_factory.dart';

void main() {
  const factory = CarParkingPayloadFactory();
  final device = CarParkingDeviceProfile.defaults().copyWith(
    deviceId: 'DG-01',
    deviceName: 'Gateway 01',
    deviceIp: '192.168.1.10',
    devicePort: '5000',
  );

  test('cardLog payload keeps compatible shape', () {
    final row = CarParkingSignalRow.card(
      deviceProfileId: device.id,
      label: 'Entry card',
    ).copyWith(cardId: 'C123', readerIndex: 2, readerName: 'Reader 2');

    final payload = factory.cardLog(
      device: device,
      row: row,
      now: DateTime.utc(2026, 7, 1, 9, 8, 7),
    );

    expect(payload['eventType'], 'cardLog');
    expect(payload['index'], 6);
    expect(payload['timestamp'], 1782896887);
    expect(payload['data']['id'], 'DG-01');
    expect(payload['data']['deviceInfo']['deviceId'], 'DG-01');
    expect(payload['data']['cardInfo']['cardId'], 'C123');
    expect(payload['data']['cardInfo']['readerIndex'], 2);
    expect(payload['data']['cardInfo']['readerName'], 'Reader 2');
    expect(payload['data']['cardInfo']['time'], '2026-7-1 9:8:7');
  });

  test('iOStatus marks only selected input as active', () {
    final row = CarParkingSignalRow.io(
      deviceProfileId: device.id,
      label: 'Loop',
    ).copyWith(inputIndex: 3, inputName: 'Button 3');

    final payload = factory.ioStatus(device: device, row: row);
    final inputs = payload['data']['inputStatus'] as List<dynamic>;
    final active = inputs.where((item) => item['value'] == 1).toList();

    expect(payload['eventType'], 'iOStatus');
    expect(inputs.length, 8);
    expect(active.length, 1);
    expect(active.single['inputIndex'], 3);
    expect((payload['data']['relayStatus'] as List<dynamic>).length, 8);
  });

  test('connectStatus payload keeps compatible shape', () {
    final payload = factory.connectStatus(device);

    expect(payload['eventType'], 'connectStatus');
    expect(payload['data']['connectStatus'], 'connected');
    expect(payload['data']['deviceInfo']['deviceId'], 'DG-01');
    expect(payload['data']['id'], 'DG-01');
  });
}
