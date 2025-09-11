import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/device_row.dart';

class SocketServerViewModel extends ChangeNotifier {
  List<DeviceRow> rows = [];
  String serverStatus = "Server chưa chạy";
  bool isServerRunning = false;
  int clientsCount = 0;
  File? _dataFile;

  Map<String, dynamic> deviceInfo = {};
  Directory storage = Directory.systemTemp; // giả sử

  SocketServerViewModel() {
    _init();
  }

  Future<void> _init() async {
    final dir = await Directory.systemTemp.createTemp("socket_test");
    storage = dir;
    _dataFile = File("${dir.path}/rows.json");
    await loadData();
  }

  /// ==== Row Operations ====
  void addRow(RowType type) {
    rows.add(DeviceRow(type: type));
    saveData();
    notifyListeners();
  }

  void removeLastRow() {
    if (rows.isNotEmpty) {
      rows.removeLast();
      saveData();
      notifyListeners();
    }
  }

  void setDeviceInfo(Map<String, dynamic> info) {
    deviceInfo = info;
    saveData();
    notifyListeners();
  }

  /// ==== Save / Load ====
  Future<void> saveData() async {
    if (_dataFile == null) return;

    final data = {
      "rows": rows.map((r) => r.toJson()).toList(),
      "deviceInfo": deviceInfo,
    };

    await _dataFile!.writeAsString(jsonEncode(data));
  }

  Future<void> loadData() async {
    if (_dataFile != null && await _dataFile!.exists()) {
      final jsonString = await _dataFile!.readAsString();
      final data = jsonDecode(jsonString);

      rows.clear();
      if (data["rows"] != null) {
        for (var rowData in data["rows"]) {
          rows.add(DeviceRow.fromJson(rowData));
        }
      }
      if (data["deviceInfo"] != null) {
        deviceInfo = Map<String, dynamic>.from(data["deviceInfo"]);
      }
    }

    if (rows.isEmpty) {
      // mặc định ít nhất 1 dòng
      rows.add(DeviceRow(type: RowType.card));
    }

    notifyListeners();
  }

  /// ==== Fake send functions ====
  void sendCard(String cardNumber, String reader) {
    print("📤 Send Card Event: card=$cardNumber, reader=$reader");
  }

  void sendIoStatus(String inputName) {
    if (inputName.isEmpty) return;

    final ioPayload = {
      "deviceInfo": deviceInfo,
      "id": deviceInfo["deviceId"] ?? "unknown",
      "inputStatus": List.generate(8, (i) {
        final name =
            [
              "Button 1",
              "Button 2",
              "Button 3",
              "Button 4",
              "Aux 1",
              "Aux 2",
              "Aux 3",
              "Aux 4",
            ][i];
        return {
          "inputIndex": i + 1,
          "inputName": name,
          "value": name == inputName ? 1 : 0,
        };
      }),
      "relayStatus": List.generate(8, (i) {
        return {"relayIndex": i + 1, "relayName": "Relay ${i + 1}", "value": 0};
      }),
    };

    print("📤 Send IO Event: ${jsonEncode(ioPayload)}");
  }
}
