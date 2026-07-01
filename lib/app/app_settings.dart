import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({required this.themeMode});

  factory AppSettings.defaults() {
    return const AppSettings(themeMode: ThemeMode.system);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(themeMode: _themeModeFromName(json['themeMode']));
  }

  final ThemeMode themeMode;

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.name};
  }

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }

  static ThemeMode _themeModeFromName(Object? value) {
    return switch (value?.toString()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
