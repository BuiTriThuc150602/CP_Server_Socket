import 'package:flutter/material.dart';
import 'package:socket_server/app/app_settings.dart';
import 'package:socket_server/core/storage/app_settings_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppSettingsRepository? repository})
    : _repository = repository ?? AppSettingsRepository();

  final AppSettingsRepository _repository;
  AppSettings _settings = AppSettings.defaults();
  bool _loaded = false;

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> cycleThemeMode() {
    final next = switch (themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    return setThemeMode(next);
  }
}
