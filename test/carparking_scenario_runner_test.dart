import 'package:flutter_test/flutter_test.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';
import 'package:socket_server/modules/carparking/services/carparking_scenario_runner.dart';

void main() {
  test('runs enabled rows sequentially and stops after one loop', () async {
    final runner = CarParkingScenarioRunner();
    final sent = <String>[];
    final rows = [
      CarParkingSignalRow.card(
        deviceProfileId: 'device',
        label: 'A',
      ).copyWith(id: 'a', delayMs: 1),
      CarParkingSignalRow.card(
        deviceProfileId: 'device',
        label: 'B',
      ).copyWith(id: 'b', delayMs: 1),
      CarParkingSignalRow.card(
        deviceProfileId: 'device',
        label: 'C',
      ).copyWith(id: 'c', enabled: false, delayMs: 1),
    ];

    await runner.start(
      rows: rows,
      scenario: CarParkingScenario.defaults().copyWith(
        loopCount: 1,
        defaultDelayMs: 1,
      ),
      sender: (row) async => sent.add(row.id),
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(sent, ['a', 'b']);
    expect(runner.snapshot.status, ScenarioRunnerStatus.stopped);
    await runner.dispose();
  });
}
