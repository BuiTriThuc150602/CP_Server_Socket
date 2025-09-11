import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_server/models/device_info.dart';

class DeviceConfigPage extends StatefulWidget {
  final DeviceInfo? deviceInfo;
  DeviceConfigPage({this.deviceInfo});

  @override
  _DeviceConfigPageState createState() => _DeviceConfigPageState();
}

class _DeviceConfigPageState extends State<DeviceConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController idController;
  late TextEditingController ipController;
  late TextEditingController nameController;
  late TextEditingController portController;
  late TextEditingController manuController;
  late TextEditingController modelController;
  late TextEditingController baudRateController;
  late TextEditingController comNameController;

  @override
  void initState() {
    super.initState();
    final d = widget.deviceInfo ?? DeviceInfo();
    idController = TextEditingController(text: d.deviceId);
    ipController = TextEditingController(text: d.deviceIp);
    nameController = TextEditingController(text: d.deviceName);
    portController = TextEditingController(text: d.devicePort);
    manuController = TextEditingController(text: d.manufacturer);
    modelController = TextEditingController(text: d.modelName);
    baudRateController = TextEditingController(text: d.baudRate);
    comNameController = TextEditingController(text: d.comName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cấu hình Device")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("Device ID", idController),
              _buildField("Device IP", ipController),
              _buildField("Device Name", nameController),
              _buildField("Device Port", portController),
              _buildField("Manufacturer", manuController),
              _buildField("Model Name", modelController),
              _buildField("BaudRate", baudRateController),
              _buildField("COM Name", comNameController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final device = DeviceInfo(
                      deviceId: idController.text,
                      deviceIp: ipController.text,
                      deviceName: nameController.text,
                      devicePort: portController.text,
                      manufacturer: manuController.text,
                      modelName: modelController.text,
                      baudRate: baudRateController.text,
                      comName: comNameController.text
                    );
                    await _saveDevice(device);
                    Navigator.pop(context, device);
                  }
                },
                child: Text("Lưu"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (v) => isRequired && (v == null || v.isEmpty) ? "Không được bỏ trống" : null,
      ),
    );
  }

  Future<void> _saveDevice(DeviceInfo device) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/device.json");
    await file.writeAsString(jsonEncode(device.toJson()));
  }
}
