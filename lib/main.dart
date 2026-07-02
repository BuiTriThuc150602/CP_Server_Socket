import 'package:flutter/material.dart';
import 'package:testdeck/app/app.dart';
import 'package:testdeck/core/logging/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.instance.init();
  runApp(const TestDeckApp());
}

class MyApp extends TestDeckApp {
  const MyApp({super.key});
}
