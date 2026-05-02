import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _colorKey = 'primary_color';

  static ThemeMode _themeMode = ThemeMode.system;
  static Color _primaryColor = const Color(0xFF6200EE);

  static const List<Color> _rainbowColors = [
    Color(0xFF6200EE),
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lime,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.brown,
    Colors.grey,
    Colors.black,
  ];

  static final List<VoidCallback> _listeners = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);
    final colorHex = prefs.getString(_colorKey);

    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    if (colorHex != null) {
      _primaryColor = Color(int.parse(colorHex));
    }
  }

  static ThemeMode get themeMode => _themeMode;
  static Color get primaryColor => _primaryColor;
  static List<Color> get rainbowColors => _rainbowColors;

  static void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
    _notifyListeners();
  }

  static void setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, color.value.toRadixString(16));
    _notifyListeners();
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: _getForegroundColor(),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _getForegroundColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: _getForegroundColor(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF121212);
    const darkCardColor = Color(0xFF1E1E1E);
    const darkSurfaceColor = Color(0xFF2C2C2C);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: darkSurfaceColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: _getForegroundColor(),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        color: darkCardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _getForegroundColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: _getForegroundColor(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }

  static Color _getForegroundColor() {
    return _primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}