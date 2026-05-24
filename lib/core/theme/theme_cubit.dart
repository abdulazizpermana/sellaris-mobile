import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
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

class LocaleCubit extends Cubit<Locale> {
  static const _localeKey = 'sellaris_locale';
  final SharedPreferences _prefs;

  LocaleCubit._(this._prefs, Locale state) : super(state);

  static Future<LocaleCubit> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localeKey) ?? 'id';
    return LocaleCubit._(prefs, _fromString(raw));
  }

  Future<void> updateLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
    emit(locale);
  }

  static Locale _fromString(String raw) {
    switch (raw) {
      case 'en':
        return const Locale('en');
      default:
        return const Locale('id');
    }
  }
}
