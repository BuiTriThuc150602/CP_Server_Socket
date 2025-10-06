import 'dart:convert';

class SocketServerInfo {
  String serverIp;
  String serverPort;

  SocketServerInfo({
    this.serverIp = '127.0.0.1', // Default IP
    this.serverPort = '1234', // Default Port
  });

  factory SocketServerInfo.fromJson(Map<String, dynamic> json) {
    return SocketServerInfo(
      serverIp: json['serverIp'] ?? '127.0.0.1',
      serverPort: json['serverPort'] ?? '1234',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverIp': serverIp,
      'serverPort': serverPort,
    };
  }
}