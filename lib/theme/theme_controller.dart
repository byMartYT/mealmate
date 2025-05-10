import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences p) {
    final raw = p.getString(_key) ?? 'system';
    return ThemeMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(prefsProvider)),
);

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 32, 172, 0)),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color.fromARGB(255, 32, 172, 0),
    brightness: Brightness.dark,
  ),
);
