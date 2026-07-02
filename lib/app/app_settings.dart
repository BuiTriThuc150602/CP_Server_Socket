import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({required this.themeMode, required this.terminalWarningDismissed});

  factory AppSettings.defaults() {
    return const AppSettings(themeMode: ThemeMode.system, terminalWarningDismissed: false);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(themeMode: _themeModeFromName(json['themeMode']), terminalWarningDismissed: json['terminalWarningDismissed'] == true);
  }

  final ThemeMode themeMode;
  final bool terminalWarningDismissed;

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.name, 'terminalWarningDismissed': terminalWarningDismissed};
  }

  AppSettings copyWith({ThemeMode? themeMode, bool? terminalWarningDismissed}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode, terminalWarningDismissed: terminalWarningDismissed ?? this.terminalWarningDismissed);
  }

  static ThemeMode _themeModeFromName(Object? value) {
    return switch (value?.toString()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
