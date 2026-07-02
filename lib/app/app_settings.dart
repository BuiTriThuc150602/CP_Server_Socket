import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.localeCode,
    required this.terminalShellCommand,
    required this.terminalShellLaunchMode,
    required this.terminalWarningDismissed,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.system,
      localeCode: 'system',
      terminalShellCommand: '',
      terminalShellLaunchMode: '',
      terminalWarningDismissed: false,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: _themeModeFromName(json['themeMode']),
      localeCode: _localeCode(json['localeCode']),
      terminalShellCommand: (json['terminalShellCommand'] ?? '').toString(),
      terminalShellLaunchMode:
          (json['terminalShellLaunchMode'] ?? '').toString(),
      terminalWarningDismissed: json['terminalWarningDismissed'] == true,
    );
  }

  final ThemeMode themeMode;
  final String localeCode;
  final String terminalShellCommand;
  final String terminalShellLaunchMode;
  final bool terminalWarningDismissed;

  Locale? get locale {
    return switch (localeCode) {
      'en' => const Locale('en'),
      'vi' => const Locale('vi'),
      _ => null,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'localeCode': localeCode,
      'terminalShellCommand': terminalShellCommand,
      'terminalShellLaunchMode': terminalShellLaunchMode,
      'terminalWarningDismissed': terminalWarningDismissed,
    };
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    String? terminalShellCommand,
    String? terminalShellLaunchMode,
    bool? terminalWarningDismissed,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      terminalShellCommand: terminalShellCommand ?? this.terminalShellCommand,
      terminalShellLaunchMode:
          terminalShellLaunchMode ?? this.terminalShellLaunchMode,
      terminalWarningDismissed:
          terminalWarningDismissed ?? this.terminalWarningDismissed,
    );
  }

  static ThemeMode _themeModeFromName(Object? value) {
    return switch (value?.toString()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _localeCode(Object? value) {
    return switch (value?.toString()) {
      'en' => 'en',
      'vi' => 'vi',
      _ => 'system',
    };
  }
}
