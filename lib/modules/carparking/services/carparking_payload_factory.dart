import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:socket_server/modules/carparking/models/carparking_models.dart';

class CarParkingPayloadFactory {
  const CarParkingPayloadFactory();

  Map<String, dynamic> connectStatus(CarParkingDeviceProfile device) {
    return {
      'eventType': 'connectStatus',
      'data': {
        'connectStatus': 'connected',
        'deviceInfo': device.toCompatibleDeviceInfoJson(),
        'id': device.deviceId,
      },
    };
  }

  Map<String, dynamic> cardLog({
    required CarParkingDeviceProfile device,
    required CarParkingSignalRow row,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return {
      'data': {
        'cardInfo': {
          'cardId': row.cardId,
          'readerIndex': row.readerIndex,
          'readerName':
              row.readerName.isEmpty
                  ? 'Reader ${row.readerIndex}'
                  : row.readerName,
          'time': DateFormat('yyyy-M-d H:m:s').format(timestamp),
        },
        'deviceInfo': device.toCompatibleDeviceInfoJson(),
        'id': device.deviceId,
      },
      'eventType': 'cardLog',
      'index': 6,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> ioStatus({
    required CarParkingDeviceProfile device,
    required CarParkingSignalRow row,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return {
      'data': {
        'deviceInfo': device.toCompatibleDeviceInfoJson(),
        'inputStatus': inputStatuses(selectedInputIndex: row.inputIndex),
        'relayStatus': relayStatuses(),
        'id': device.deviceId,
      },
      'eventType': 'iOStatus',
      'index': 6,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }

  String encodeLine(Map<String, dynamic> payload) => jsonEncode(payload);

  List<Map<String, dynamic>> inputStatuses({required int selectedInputIndex}) {
    return List.generate(CarParkingConstants.inputNames.length, (index) {
      final inputIndex = index + 1;
      return {
        'inputIndex': inputIndex,
        'inputName': CarParkingConstants.inputNames[index],
        'value': inputIndex == selectedInputIndex ? 1 : 0,
      };
    });
  }

  List<Map<String, dynamic>> relayStatuses() {
    return List.generate(8, (index) {
      final relayIndex = index + 1;
      return {
        'relayIndex': relayIndex,
        'relayName': index < 4 ? 'Lock $relayIndex' : 'AuxOut ${index - 3}',
        'value': 0,
      };
    });
  }
}

class CarParkingConstants {
  const CarParkingConstants._();

  static const inputNames = [
    'Button 1',
    'Button 2',
    'Button 3',
    'Button 4',
    'Aux 1',
    'Aux 2',
    'Aux 3',
    'Aux 4',
  ];
}
