import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class AdminPalette {
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color muted;
  final Color success;
  final Color warning;
  final Color danger;
  final bool isDark;

  AdminPalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.muted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.isDark,
  });

  factory AdminPalette.of(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    return AdminPalette(
      background: theme.backgroundColor,
      surface: theme.cardColor,
      primary: theme.primaryColor,
      secondary: theme.secondaryColor,
      accent: theme.accentColor,
      text: theme.textColor,
      textSecondary: theme.textSecondaryColor,
      border: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB),
      muted: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      success: const Color(0xFF10B981),
      warning: const Color(0xFFF59E0B),
      danger: const Color(0xFFEF4444),
      isDark: isDark,
    );
  }
}
