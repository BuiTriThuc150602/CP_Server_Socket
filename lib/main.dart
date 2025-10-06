import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:socket_server/models/data_row.dart';
import 'package:socket_server/models/device_info.dart';
import 'package:socket_server/models/socket_server_info.dart';
import 'package:socket_server/views/device_config_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Socket Server', theme: ThemeData(primarySwatch: Colors.blue), home: SocketServerPage());
  }
}

class SocketServerPage extends StatefulWidget {
  @override
  _SocketServerPageState createState() => _SocketServerPageState();
}

class _SocketServerPageState extends State<SocketServerPage> {
  ServerSocket? _serverSocket;
  List<Socket> _clients = [];
  List<DeviceRow> _rows = [];
  Timer? _heartbeatTimer;
  bool _isServerRunning = false;
  String _serverStatus = "Server đã dừng";
  File? _dataFile;
  File? _deviceFile;
  File? _socketServerFile;
  DeviceInfo? _deviceInfo;
  SocketServerInfo? _socketServerInfo;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _initDataFile();
    await _loadData();
    await _loadSocketServerInfo();
    _startServer();
    _startHeartbeat();
  }

  Future<void> _initDataFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _dataFile = File('${directory.path}/socket_server_data.json');
      _deviceFile = File('${directory.path}/device.json');
      _socketServerFile = File('${directory.path}/socket_server.json');
    } catch (e) {
      print('Error initializing data file: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      if (_dataFile != null && await _dataFile!.exists()) {
        final jsonString = await _dataFile!.readAsString();
        final data = jsonDecode(jsonString);

        setState(() {
          _rows.clear();
          if (data['rows'] != null) {
            for (var rowData in data['rows']) {
              _rows.add(DeviceRow.fromJson(rowData));
            }
          }

          while (_rows.length < 4) {
            _rows.add(DeviceRow.card());
          }
        });
      } else {
        setState(() {
          _rows = List.generate(4, (_) => DeviceRow.card());
        });
      }

      if (_deviceFile != null && await _deviceFile!.exists()) {
        final jsonString = await _deviceFile!.readAsString();
        final deviceMap = jsonDecode(jsonString);
        _deviceInfo = DeviceInfo.fromJson(deviceMap);
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _rows = List.generate(4, (_) => DeviceRow.card());
      });
    }
  }

  Future<void> _loadSocketServerInfo() async {
    try {
      if (_socketServerFile != null && await _socketServerFile!.exists()) {
        final jsonString = await _socketServerFile!.readAsString();
        final socketServerMap = jsonDecode(jsonString);
        _socketServerInfo = SocketServerInfo.fromJson(socketServerMap);
      } else {
        _socketServerInfo = SocketServerInfo(); // Use default values if file doesn't exist
      }
    } catch (e) {
      print('Error loading socket server info: $e');
      _socketServerInfo = SocketServerInfo(); // Fallback to default on error
    }
  }

  Future<void> _saveData() async {
    try {
      if (_dataFile != null) {
        final data = {'rows': _rows.map((row) => row.toJson()).toList(), 'lastSaved': DateTime.now().toIso8601String()};

        await _dataFile!.writeAsString(jsonEncode(data));
        print('Data saved successfully');
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _startServer() async {
    try {
      final ip = _socketServerInfo?.serverIp ?? '192.168.1.8';
      final port = int.tryParse(_socketServerInfo?.serverPort ?? '8080') ?? 8080;
      _serverSocket = await ServerSocket.bind(ip, port);
      setState(() {
        _isServerRunning = true;
        _serverStatus = "Server đang chạy tại $ip:$port";
      });

      _serverSocket!.listen((Socket client) {
        print('Client connected: ${client.remoteAddress.address}:${client.remotePort}');
        setState(() {
          _clients.add(client);
        });

        client.listen(
          (data) {
            // Xử lý dữ liệu từ client nếu cần
            print('Received from client: ${String.fromCharCodes(data)}');
          },
          onDone: () {
            print('Client disconnected');
            setState(() {
              _clients.remove(client);
            });
          },
          onError: (error) {
            print('Client error: $error');
            setState(() {
              _clients.remove(client);
            });
          },
        );
      });
    } catch (e) {
      setState(() {
        _serverStatus = "Lỗi khởi động server: $e";
      });
      print('Error starting server: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    if (_deviceInfo == null){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa cấu hình thông tin thiết bị')));
      return;
    }
    final heartbeatData = {
      "eventType": "connectStatus",
      "data": {"connectStatus": "connected", "deviceInfo": _deviceInfo!.toJson(), "id": _deviceInfo!.deviceId},
    };
    _sendToClients(jsonEncode(heartbeatData));
  }

  void _sendCardData(String cardId, String readerIndex) {
    if (cardId.isEmpty || readerIndex.isEmpty) return;
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    final timeString = "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";

    final cardData = {
      "data": {
        "cardInfo": {"cardId": cardId, "readerIndex": int.tryParse(readerIndex) ?? 1, "readerName": "Reader ${int.tryParse(readerIndex) ?? 1}", "time": timeString},
        "deviceInfo": _deviceInfo?.toJson() ?? {},
        "id": _deviceInfo?.deviceId ?? "",
      },
      "eventType": "cardLog",
      "index": 6,
      "timestamp": timestamp,
    };
    _sendToClients(jsonEncode(cardData));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi iOStatus: $cardId - $readerIndex')));
  }

  void _sendIoStatus(String inputName) {
    if (_deviceInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa cấu hình thông tin thiết bị')));
      return;
    }
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    final List<Map<String, dynamic>> inputs =
        [
          {"inputIndex": 1, "inputName": "Button 1"},
          {"inputIndex": 2, "inputName": "Button 2"},
          {"inputIndex": 3, "inputName": "Button 3"},
          {"inputIndex": 4, "inputName": "Button 4"},
          {"inputIndex": 5, "inputName": "Aux 1"},
          {"inputIndex": 6, "inputName": "Aux 2"},
          {"inputIndex": 7, "inputName": "Aux 3"},
          {"inputIndex": 8, "inputName": "Aux 4"},
        ].map((item) {
          return {"inputIndex": item["inputIndex"], "inputName": item["inputName"], "value": (item["inputName"] == inputName) ? 1 : 0};
        }).toList();

    final relays = List.generate(8, (i) {
      return {"relayIndex": i + 1, "relayName": i < 4 ? "Lock ${i + 1}" : "AuxOut ${i - 3}", "value": 0};
    });

    final ioData = {
      "data": {"deviceInfo": _deviceInfo!.toJson(), "inputStatus": inputs, "relayStatus": relays, "id": _deviceInfo!.deviceId},
      "eventType": "iOStatus",      
      "index": 6,
      "timestamp": timestamp,
    };

    _sendToClients(jsonEncode(ioData));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi iOStatus: $inputName')));
  }

  void _sendToClients(String data) {
    List<Socket> clientsToRemove = [];

    for (Socket client in _clients.toList()) {
      try {
        client.write(data + '\n');
      } catch (e) {
        print('Error sending to client: $e');
        clientsToRemove.add(client);
      }
    }

    if (clientsToRemove.isNotEmpty) {
      setState(() {
        for (Socket client in clientsToRemove) {
          _clients.remove(client);
        }
      });
    }

    print('Sent to ${_clients.length} clients: $data');
  }

  Widget _buildCardReaderRow(int index) {
    final row = _rows[index];
    if (row.type == RowType.card) {
      return _buildCardRow(row, index);
    } else {
      return _buildIoRow(row, index);
    }
  }

  Widget _buildCardRow(DeviceRow row, int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(flex: 2, child: TextField(controller: row.cardController, decoration: InputDecoration(labelText: "Số Thẻ"), onChanged: (_) => _saveData())),
          SizedBox(width: 16),
          Expanded(flex: 2, child: TextField(controller: row.readerController, decoration: InputDecoration(labelText: "Chân Reader"), onChanged: (_) => _saveData())),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              _sendCardData(row.cardController.text, row.readerController.text);
            },
            child: Text("Gửi"),
          ),
        ],
      ),
    );
  }

  Widget _buildIoRow(DeviceRow row, int index) {
    final inputNames = ["Button 1", "Button 2", "Button 3", "Button 4", "Aux 1", "Aux 2", "Aux 3", "Aux 4"];
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.orange.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: row.selectedInputName,
              items: inputNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
              onChanged: (val) {
                setState(() {
                  row.selectedInputName = val!;
                });
                _saveData();
              },
              decoration: InputDecoration(labelText: "Chọn Input"),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              _sendIoStatus(row.selectedInputName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, textStyle: TextStyle(color: Colors.white)),
            child: Text("Gửi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOCKET SERVER'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceConfigPage(
                    deviceInfo: _deviceInfo,
                    socketServerInfo: _socketServerInfo,
                  ),
                ),
              );
              if (result != null && result is DeviceInfo) {
                setState(() {
                  _deviceInfo = result;
                  // Reload socket server info in case it was updated on the config page
                  _loadSocketServerInfo();
                  // Restart server with new config
                  _serverSocket?.close();
                  _startServer();
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: _isServerRunning ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              children: [
                Icon(_isServerRunning ? Icons.check_circle : Icons.error, color: _isServerRunning ? Colors.green : Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text(_serverStatus, style: TextStyle(fontWeight: FontWeight.bold, color: _isServerRunning ? Colors.green.shade800 : Colors.red.shade800))),
                Expanded(child: Text('Dữ liệu lưu tại : ${_dataFile?.path}', style: TextStyle(fontWeight: FontWeight.bold, color: _isServerRunning ? Colors.green.shade800 : Colors.red.shade800))),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _clients.isNotEmpty ? Colors.blue.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20), border: Border.all(color: _clients.isNotEmpty ? Colors.blue : Colors.grey)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 16, color: _clients.isNotEmpty ? Colors.blue.shade700 : Colors.grey.shade600),
                      SizedBox(width: 4),
                      Text('Clients: ${_clients.length}', style: TextStyle(fontWeight: FontWeight.bold, color: _clients.isNotEmpty ? Colors.blue.shade700 : Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card reader rows
          Expanded(child: ListView.builder(itemCount: _rows.length, itemBuilder: (context, index) => _buildCardReaderRow(index))),
          // Add/Remove buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final type = await showDialog<RowType>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text("Chọn loại dòng"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [ListTile(leading: Icon(Icons.credit_card), title: Text("Card"), onTap: () => Navigator.pop(context, RowType.card)), ListTile(leading: Icon(Icons.sensors), title: Text("Vòng từ (iOStatus)"), onTap: () => Navigator.pop(context, RowType.io))],
                            ),
                          ),
                    );
                    if (type != null) {
                      setState(() {
                        if (type == RowType.card) {
                          _rows.add(DeviceRow.card());
                        } else {
                          _rows.add(DeviceRow.io());
                        }
                      });
                      _saveData();
                    }
                  },
                  icon: Icon(Icons.add),
                  label: Text("Thêm dòng"),
                ),

                ElevatedButton.icon(
                  onPressed:
                      _rows.length > 1
                          ? () {
                            setState(() {
                              _rows.last.dispose(); // Giải phóng controller
                              _rows.removeLast();
                            });
                            _saveData(); // Lưu khi xóa dòng
                          }
                          : null,
                  icon: Icon(Icons.remove),
                  label: Text('Xóa dòng'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _serverSocket?.close();
    for (Socket client in _clients) {
      client.close();
    }
    for (DeviceRow row in _rows) {
      row.dispose();
    }
    // Lưu dữ liệu cuối cùng khi tắt app
    _saveData();
    super.dispose();
  }
}
