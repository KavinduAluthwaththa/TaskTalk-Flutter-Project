import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 18.0; // Larger default font for elderly users
  bool _highContrast = false;

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _fontSize = prefs.getDouble('font_size') ?? 18.0;
    _highContrast = prefs.getBool('high_contrast') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', _fontSize);
    notifyListeners();
  }

  Future<void> toggleHighContrast() async {
    _highContrast = !_highContrast;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', _highContrast);
    notifyListeners();
  }

  ThemeData get themeData {
    if (_highContrast) {
      return _getHighContrastTheme();
    }
    
    return _isDarkMode ? _getDarkTheme() : _getLightTheme();
  }

  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: _getTextTheme(Colors.black87),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontSize: _fontSize),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        iconSize: 32,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: _fontSize + 4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      textTheme: _getTextTheme(Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontSize: _fontSize),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        iconSize: 32,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: _fontSize + 4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  ThemeData _getHighContrastTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.yellow,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: _isDarkMode ? Colors.yellow : Colors.black,
        onPrimary: _isDarkMode ? Colors.black : Colors.white,
        surface: _isDarkMode ? Colors.black : Colors.white,
        onSurface: _isDarkMode ? Colors.white : Colors.black,
      ),
      textTheme: _getTextTheme(_isDarkMode ? Colors.white : Colors.black),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          backgroundColor: _isDarkMode ? Colors.yellow : Colors.black,
          foregroundColor: _isDarkMode ? Colors.black : Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        iconSize: 32,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _isDarkMode ? Colors.yellow : Colors.black,
        foregroundColor: _isDarkMode ? Colors.black : Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(
            color: _isDarkMode ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black,
        titleTextStyle: TextStyle(
          fontSize: _fontSize + 4,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  TextTheme _getTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: _fontSize + 16, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: TextStyle(fontSize: _fontSize + 12, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: TextStyle(fontSize: _fontSize + 8, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: TextStyle(fontSize: _fontSize + 8, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: _fontSize + 2, color: textColor),
      bodyMedium: TextStyle(fontSize: _fontSize, color: textColor),
      bodySmall: TextStyle(fontSize: _fontSize - 2, color: textColor),
      labelLarge: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500, color: textColor),
      labelMedium: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: TextStyle(fontSize: _fontSize - 2, fontWeight: FontWeight.w500, color: textColor),
    );
  }
}
