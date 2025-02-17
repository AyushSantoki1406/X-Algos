import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeManager() {
    loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify widgets to rebuild
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'isDarkMode', _themeMode == ThemeMode.dark); // Save the theme mode
    notifyListeners(); // Update UI without restarting the activity
  }

  Color get textColor =>
      _themeMode == ThemeMode.dark ? Colors.white : Colors.black;
}
