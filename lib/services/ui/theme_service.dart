import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  ThemeMode _themeMode = ThemeMode.light;
  String _themeName = 'Claro';
  
  ThemeMode get themeMode => _themeMode;
  String get themeName => _themeName;
  
  ThemeService() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'Claro';
    _setTheme(themeName);
  }
  
  Future<void> setTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
    _setTheme(themeName);
  }
  
  void _setTheme(String themeName) {
    _themeName = themeName;
    
    switch (themeName) {
      case 'Claro':
        _themeMode = ThemeMode.light;
        break;
      case 'Oscuro':
        _themeMode = ThemeMode.dark;
        break;
      case 'Automático':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
    
    notifyListeners();
  }
  
  ThemeData get lightTheme => AppTheme.lightTheme;
  
  ThemeData get darkTheme => AppTheme.darkTheme;
  
  List<String> get availableThemes => ['Claro', 'Oscuro', 'Automático'];
}
