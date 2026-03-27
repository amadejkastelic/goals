import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _useDynamicColorsKey = 'use_dynamic_colors';

  ThemeMode _themeMode = ThemeMode.system;
  ColorScheme? _dynamicLightColorScheme;
  ColorScheme? _dynamicDarkColorScheme;
  bool _useDynamicColors = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get useDynamicColors => _useDynamicColors;
  ColorScheme? get dynamicLightColorScheme => _dynamicLightColorScheme;
  ColorScheme? get dynamicDarkColorScheme => _dynamicDarkColorScheme;

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_themeModeKey);
    if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    _useDynamicColors = prefs.getBool(_useDynamicColorsKey) ?? true;
    notifyListeners();
  }

  void setDynamicColorSchemes(ColorScheme? light, ColorScheme? dark) {
    if (_useDynamicColors) {
      _dynamicLightColorScheme = light;
      _dynamicDarkColorScheme = dark;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await prefs.setString(_themeModeKey, modeStr);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> toggleDynamicColors() async {
    _useDynamicColors = !_useDynamicColors;
    if (!_useDynamicColors) {
      _dynamicLightColorScheme = null;
      _dynamicDarkColorScheme = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorsKey, _useDynamicColors);
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);
}
