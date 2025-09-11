// import 'dart:convert';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import '../models/device_row.dart';

// class StorageService {
//   File? _dataFile;

//   Future<void> init() async {
//     final dir = await getApplicationDocumentsDirectory();
//     _dataFile = File('${dir.path}/socket_server_data.json');
//   }

//   Future<List<DeviceRow>> loadData() async {
//     if (_dataFile == null) await init();
//     if (_dataFile != null && await _dataFile!.exists()) {
//       final jsonString = await _dataFile!.readAsString();
//       final data = jsonDecode(jsonString);
//       return (data['rows'] as List).map((r) => DeviceRow.fromJson(r)).toList();
//     }
//     return List.generate(4, (_) => DeviceRow.card());
//   }

//   Future<void> saveData(List<DeviceRow> rows) async {
//     if (_dataFile == null) await init();
//     final data = {
//       'rows': rows.map((r) => r.toJson()).toList(),
//       'lastSaved': DateTime.now().toIso8601String(),
//     };
//     await _dataFile!.writeAsString(jsonEncode(data));
//   }

//   String? get path => _dataFile?.path;
// }
