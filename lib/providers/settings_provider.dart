import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String currency = 'zł';

  static const themePrefsKey = 'theme';
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

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (kDebugMode) await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePrefsKey, getThemeModeKey(themeMode));

    this.themeMode = themeMode;

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
    final prefs = await SharedPreferences.getInstance();

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

    String? currency = prefs.getString(currencyPrefsKey);
    if (currency != null) this.currency = currency;

    notifyListeners();
  }
}