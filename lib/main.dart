import 'package:flutter/material.dart';
import 'package:socket_server/app/app.dart';
import 'package:socket_server/core/logging/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.instance.init();
  runApp(const SocketTestingToolsApp());
}

class MyApp extends SocketTestingToolsApp {
  const MyApp({super.key});
}
