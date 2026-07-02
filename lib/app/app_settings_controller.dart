import 'package:flutter/material.dart';
import 'package:testdeck/app/app_settings.dart';
import 'package:testdeck/core/storage/app_settings_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppSettingsRepository? repository})
    : _repository = repository ?? AppSettingsRepository();

  final AppSettingsRepository _repository;
  AppSettings _settings = AppSettings.defaults();
  bool _loaded = false;

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  String get localeCode => _settings.localeCode;
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

  Future<void> setLocaleCode(String localeCode) async {
    _settings = _settings.copyWith(localeCode: localeCode);
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> setTerminalShellCommand(
    String command, {
    String launchMode = '',
  }) async {
    _settings = _settings.copyWith(
      terminalShellCommand: command,
      terminalShellLaunchMode: launchMode,
    );
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> dismissTerminalWarning() async {
    if (_settings.terminalWarningDismissed) {
      return;
    }
    _settings = _settings.copyWith(terminalWarningDismissed: true);
    notifyListeners();
    await _repository.save(_settings);
  }
}
