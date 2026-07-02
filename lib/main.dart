import 'package:flutter/material.dart';
import 'package:fluxlab/app/app.dart';
import 'package:fluxlab/core/logging/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.instance.init();
  runApp(const FluxLabApp());
}

class MyApp extends FluxLabApp {
  const MyApp({super.key});
}
