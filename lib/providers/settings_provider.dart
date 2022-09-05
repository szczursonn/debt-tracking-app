import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _loading = false;

  ThemeMode themeMode = ThemeMode.system;
  bool useMaterial3 = false;
  String currency = 'zł';

  static const themePrefsKey = 'theme';
  static const useMaterial3PrefsKey = 'material3';
  static const currencyPrefsKey = 'currency';

  static const lightThemeKey = 'light';
  static const darkThemeKey = 'dark';
  static const systemThemeKey = 'system';

  static String getThemeModeKey(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return lightThemeKey;
      case ThemeMode.dark:
        return darkThemeKey;
      case ThemeMode.system:
        return systemThemeKey;
    }
  }

  bool get loading => _loading;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (kDebugMode) await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePrefsKey, getThemeModeKey(themeMode));

    this.themeMode = themeMode;

    notifyListeners();
  }

  Future<void> setUseMaterial3(bool value) async {
    if (kDebugMode) await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(useMaterial3PrefsKey, value);

    useMaterial3 = value;

    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    if (kDebugMode) await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currencyPrefsKey, currency);

    this.currency = currency;

    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    // THEME
    String? themeKey = prefs.getString(themePrefsKey);
    switch (themeKey) {
      case lightThemeKey:
        themeMode = ThemeMode.light;
        break;
      case darkThemeKey:
        themeMode = ThemeMode.dark;
        break;
      case systemThemeKey:
        themeMode = ThemeMode.system;
        break;
    }
    // MATERIAL3
    bool? useMaterial3 = prefs.getBool(useMaterial3PrefsKey);
    if (useMaterial3 != null) this.useMaterial3 = useMaterial3;
    // CURRENCY
    String? currency = prefs.getString(currencyPrefsKey);
    if (currency != null) this.currency = currency;

    _loading = false;
    notifyListeners();
  }
}