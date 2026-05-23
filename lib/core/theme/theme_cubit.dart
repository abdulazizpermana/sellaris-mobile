import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themeKey = 'sellaris_theme_mode';
  final SharedPreferences _prefs;

  ThemeCubit._(this._prefs, ThemeMode state) : super(state);

  static Future<ThemeCubit> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey) ?? 'system';
    return ThemeCubit._(prefs, _fromString(raw));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, _toString(mode));
    emit(mode);
  }

  static ThemeMode _fromString(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
