import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManagerService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';

  // Temas disponibles
  static const List<Map<String, dynamic>> availableThemes = [
    {
      'name': 'Clásico',
      'id': 'classic',
      'primary': Color(0xFF2196F3),
      'secondary': Color(0xFF03DAC6),
      'accent': Color(0xFFFF9800),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFC107),
      'error': Color(0xFFF44336),
    },
    {
      'name': 'Oscuro',
      'id': 'dark',
      'primary': Color(0xFFBB86FC),
      'secondary': Color(0xFF03DAC6),
      'accent': Color(0xFFFF6B35),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFC107),
      'error': Color(0xFFCF6679),
    },
    {
      'name': 'Rosa',
      'id': 'pink',
      'primary': Color(0xFFE91E63),
      'secondary': Color(0xFFF8BBD9),
      'accent': Color(0xFFFF4081),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFC107),
      'error': Color(0xFFF44336),
    },
    {
      'name': 'Verde',
      'id': 'green',
      'primary': Color(0xFF4CAF50),
      'secondary': Color(0xFF81C784),
      'accent': Color(0xFF8BC34A),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFC107),
      'error': Color(0xFFF44336),
    },
    {
      'name': 'Púrpura',
      'id': 'purple',
      'primary': Color(0xFF9C27B0),
      'secondary': Color(0xFFBA68C8),
      'accent': Color(0xFFE1BEE7),
      'success': Color(0xFF4CAF50),
      'warning': Color(0xFFFFC107),
      'error': Color(0xFFF44336),
    },
  ];

  // Fuentes disponibles
  static const List<Map<String, dynamic>> availableFonts = [
    {'name': 'Roboto', 'family': 'Roboto'},
    {'name': 'Open Sans', 'family': 'OpenSans'},
    {'name': 'Lato', 'family': 'Lato'},
    {'name': 'Poppins', 'family': 'Poppins'},
    {'name': 'Inter', 'family': 'Inter'},
    {'name': 'Montserrat', 'family': 'Montserrat'},
  ];

  // Tamaños de fuente disponibles
  static const List<Map<String, dynamic>> availableFontSizes = [
    {'name': 'Pequeño', 'size': 12.0, 'multiplier': 0.9},
    {'name': 'Normal', 'size': 14.0, 'multiplier': 1.0},
    {'name': 'Grande', 'size': 16.0, 'multiplier': 1.1},
    {'name': 'Extra Grande', 'size': 18.0, 'multiplier': 1.2},
  ];

  String _currentTheme = 'classic';
  String _currentFontFamily = 'Roboto';
  double _currentFontSize = 14.0;
  bool _isDarkMode = false;

  String get currentTheme => _currentTheme;
  String get currentFontFamily => _currentFontFamily;
  double get currentFontSize => _currentFontSize;
  bool get isDarkMode => _isDarkMode;

  Map<String, dynamic> get currentThemeData {
    return availableThemes.firstWhere(
      (theme) => theme['id'] == _currentTheme,
      orElse: () => availableThemes.first,
    );
  }

  Map<String, dynamic> get currentFontData {
    return availableFonts.firstWhere(
      (font) => font['family'] == _currentFontFamily,
      orElse: () => availableFonts.first,
    );
  }

  Map<String, dynamic> get currentFontSizeData {
    return availableFontSizes.firstWhere(
      (size) => size['size'] == _currentFontSize,
      orElse: () => availableFontSizes[1], // Normal
    );
  }

  // Cargar configuración guardada
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString(_themeKey) ?? 'classic';
    _currentFontFamily = prefs.getString(_fontFamilyKey) ?? 'Roboto';
    _currentFontSize = prefs.getDouble(_fontSizeKey) ?? 14.0;
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  // Guardar configuración
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _currentTheme);
    await prefs.setString(_fontFamilyKey, _currentFontFamily);
    await prefs.setDouble(_fontSizeKey, _currentFontSize);
    await prefs.setBool('dark_mode', _isDarkMode);
  }

  // Cambiar tema
  Future<void> setTheme(String themeId) async {
    _currentTheme = themeId;
    await saveSettings();
    notifyListeners();
  }

  // Cambiar fuente
  Future<void> setFontFamily(String fontFamily) async {
    _currentFontFamily = fontFamily;
    await saveSettings();
    notifyListeners();
  }

  // Cambiar tamaño de fuente
  Future<void> setFontSize(double fontSize) async {
    _currentFontSize = fontSize;
    await saveSettings();
    notifyListeners();
  }

  // Alternar modo oscuro
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await saveSettings();
    notifyListeners();
  }

  // Obtener colores del tema actual
  Color get primaryColor => currentThemeData['primary'] as Color;
  Color get secondaryColor => currentThemeData['secondary'] as Color;
  Color get accentColor => currentThemeData['accent'] as Color;
  Color get successColor => currentThemeData['success'] as Color;
  Color get warningColor => currentThemeData['warning'] as Color;
  Color get errorColor => currentThemeData['error'] as Color;

  // Obtener tema de Material Design
  ThemeData get materialTheme {
    final fontSizeMultiplier = currentFontSizeData['multiplier'] as double;
    
    final baseTheme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      primaryColor: primaryColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      textTheme: baseTheme.textTheme.apply(
        fontFamily: _currentFontFamily,
        fontSizeFactor: fontSizeMultiplier,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
