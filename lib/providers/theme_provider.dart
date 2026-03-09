import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
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

  void setDynamicColorSchemes(ColorScheme? light, ColorScheme? dark) {
    if (_useDynamicColors) {
      _dynamicLightColorScheme = light;
      _dynamicDarkColorScheme = dark;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void toggleDynamicColors() {
    _useDynamicColors = !_useDynamicColors;
    if (!_useDynamicColors) {
      _dynamicLightColorScheme = null;
      _dynamicDarkColorScheme = null;
    }
    notifyListeners();
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);
}
