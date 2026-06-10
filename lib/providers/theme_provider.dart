import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark(bool value) {
    final newMode = value ? ThemeMode.dark : ThemeMode.light;
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }
}
