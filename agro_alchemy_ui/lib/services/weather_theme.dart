import 'package:flutter/material.dart';

// Create a class to manage dynamic weather themes
class WeatherTheme {
  // Define theme color schemes for different weather conditions
  static final Map<String, ThemeData> _weatherThemes = {
    'sunny': ThemeData(
      primaryColor: const Color(0xFF4CAF50),
      scaffoldBackgroundColor: const Color(0xFFFFFDE7),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
        primary: const Color(0xFF4CAF50),
        secondary: Colors.amber,
        surface: const Color(0xFFFFFDE7),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.amber.withOpacity(0.3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF4CAF50),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white70,
      ),
    ),
    
    'cloudy': ThemeData(
      primaryColor: const Color(0xFF546E7A),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF546E7A),
        brightness: Brightness.light,
        primary: const Color(0xFF546E7A),
        secondary: const Color(0xFF78909C),
        surface: const Color(0xFFF5F5F5),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.blueGrey.withOpacity(0.3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF546E7A),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF546E7A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    ),
    
    'rainy': ThemeData(
      primaryColor: const Color(0xFF1976D2),
      scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.light,
        primary: const Color(0xFF1976D2),
        secondary: const Color(0xFF64B5F6),
        surface: const Color(0xFFE3F2FD),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1976D2),
        selectedItemColor: Color(0xFFBBDEFB),
        unselectedItemColor: Colors.white70,
      ),
    ),
    
    'snow': ThemeData(
      primaryColor: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
        primary: Colors.indigo,
        secondary: Colors.lightBlue,
        surface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.indigo.withOpacity(0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.indigo,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    ),
    
    // Default theme (your original green theme)
    'default': ThemeData(
      primaryColor: const Color(0xFF36522E),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF36522E),
        brightness: Brightness.light,
        primary: const Color(0xFF36522E),
        secondary: const Color(0xFF4CAF50),
        surface: const Color(0xFFF8F9FA),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.green.withOpacity(0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF36522E),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF36522E),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
      ),
    ),
  };

  // Method to get appropriate theme based on weather condition
  static ThemeData getThemeForWeather(String? condition) {
    if (condition == null) return _weatherThemes['default']!;
    
    condition = condition.toLowerCase();
    
    if (condition.contains('sunny') || condition.contains('clear')) {
      return _weatherThemes['sunny']!;
    } else if (condition.contains('cloud') || condition.contains('overcast')) {
      return _weatherThemes['cloudy']!;
    } else if (condition.contains('rain') || condition.contains('drizzle') || 
              condition.contains('thunder') || condition.contains('storm')) {
      return _weatherThemes['rainy']!;
    } else if (condition.contains('snow') || condition.contains('sleet') || 
              condition.contains('ice')) {
      return _weatherThemes['snow']!;
    } else {
      return _weatherThemes['default']!;
    }
  }
}