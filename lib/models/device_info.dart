class DeviceInfo {
  String deviceId;
  String deviceIp;
  String deviceName;
  String devicePort;
  String manufacturer;
  String modelName;
  String protocolType;
  String baudRate;
  String comName;

  DeviceInfo({
    this.deviceId = "",
    this.deviceIp = "",
    this.deviceName = "",
    this.devicePort = "",
    this.manufacturer = "",
    this.modelName = "",
    this.protocolType = "TCP",
    this.baudRate = "",
    this.comName = "",
  });

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId,
    "deviceIp": deviceIp,
    "deviceName": deviceName,
    "devicePort": devicePort,
    "manufacturer": manufacturer,
    "modelName": modelName,
    "protocolType": protocolType,
    "baudRate": baudRate,
    "comName": comName,
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json["deviceId"] ?? "",
      deviceIp: json["deviceIp"] ?? "",
      deviceName: json["deviceName"] ?? "",
      devicePort: json["devicePort"] ?? "",
      manufacturer: json["manufacturer"] ?? "",
      modelName: json["modelName"] ?? "",
      protocolType: json["protocolType"] ?? "TCP",
      baudRate: json["baudRate"] ?? "",
      comName: json["comName"] ?? "",
    );
  }
}
