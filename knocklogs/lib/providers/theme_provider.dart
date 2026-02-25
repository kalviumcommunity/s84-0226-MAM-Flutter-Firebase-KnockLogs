import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  // Color palette
  static const Color darkGreen = Color(0xFF40513B);
  static const Color mediumGreen = Color(0xFF628141);
  static const Color cream = Color(0xFFE5D9B6);
  static const Color orange = Color(0xFFE67E22);

  bool get isDarkMode => _isDarkMode;

  // Dark theme colors
  Color get darkBackground => const Color(0xFF0D1117);
  Color get darkCard => const Color(0xFF1C2128);
  Color get darkPrimary => mediumGreen;
  Color get darkSecondary => darkGreen;
  Color get darkAccent => orange;
  Color get darkText => cream;
  Color get darkTextSecondary => cream.withOpacity(0.6);

  // Light theme colors
  Color get lightBackground => const Color(0xFFFAF8F3); // Soft cream background
  Color get lightCard => const Color(0xFFFFFFFF); // Pure white cards
  Color get lightPrimary => const Color(0xFF628141); // Medium green as primary
  Color get lightSecondary => const Color(0xFF7A9B57); // Lighter green
  Color get lightAccent => const Color(0xFFD4A574); // Soft orange-brown
  Color get lightText => const Color(0xFF2C3E2D); // Dark green text
  Color get lightTextSecondary =>
      const Color(0xFF5A6B5B); // Medium green-gray text

  // Current theme colors
  Color get backgroundColor => _isDarkMode ? darkBackground : lightBackground;
  Color get cardColor => _isDarkMode ? darkCard : lightCard;
  Color get primaryColor => _isDarkMode ? darkPrimary : lightPrimary;
  Color get secondaryColor => _isDarkMode ? darkSecondary : lightSecondary;
  Color get accentColor => _isDarkMode ? darkAccent : lightAccent;
  Color get textColor => _isDarkMode ? darkText : lightText;
  Color get textSecondaryColor =>
      _isDarkMode ? darkTextSecondary : lightTextSecondary;

  // Gradient for buttons
  LinearGradient get primaryGradient => _isDarkMode
      ? const LinearGradient(colors: [mediumGreen, darkGreen])
      : const LinearGradient(colors: [Color(0xFF628141), Color(0xFF7A9B57)]);

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
