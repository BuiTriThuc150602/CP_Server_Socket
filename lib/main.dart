import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluxlab/app/app.dart';
import 'package:fluxlab/core/logging/logger_service.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.instance.init();
  await _configureDesktopWindow();
  runApp(const FluxLabApp());
}

class MyApp extends FluxLabApp {
  const MyApp({super.key});
}

Future<void> _configureDesktopWindow() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }

  await windowManager.ensureInitialized();
  const options = WindowOptions(
    title: 'FluxLab',
    size: Size(1280, 720),
    minimumSize: Size(1024, 640),
    center: true,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
