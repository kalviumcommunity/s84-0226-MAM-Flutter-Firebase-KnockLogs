import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool compact;

  const ThemeToggleButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final width = compact ? 54.0 : 70.0;
    final height = compact ? 28.0 : 35.0;
    final knobSize = compact ? 20.0 : 25.0;
    final knobOffset = compact ? 4.0 : 5.0;

    return GestureDetector(
      onTap: theme.toggleTheme,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            colors: theme.isDarkMode
                ? [const Color(0xFF2E3A59), const Color(0xFF1A1F2E)]
                : [const Color(0xFFFFC3A0), const Color(0xFFFFEFBA)],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: theme.isDarkMode
                  ? knobOffset
                  : width - knobSize - knobOffset,
              top: knobOffset,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.isDarkMode
                      ? const Color(0xFFF4E5A1)
                      : const Color(0xFFFFD700),
                  boxShadow: [
                    BoxShadow(
                      color: theme.isDarkMode
                          ? const Color(0xFFF4E5A1).withOpacity(0.5)
                          : const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  theme.isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                  size: compact ? 12 : 14,
                  color: theme.isDarkMode
                      ? const Color(0xFF2E3A59)
                      : const Color(0xFF8B5A00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
