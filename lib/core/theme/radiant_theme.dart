import 'package:flutter/material.dart';

abstract final class RadiantColors {
  static const voidBlack = Color(0xFF050706);
  static const deepSpace = Color(0xFF09100F);
  static const surface = Color(0xFF101816);
  static const surfaceBright = Color(0xFF18231F);
  static const gold = Color(0xFFD8B65C);
  static const luminousGold = Color(0xFFFFD978);
  static const ivory = Color(0xFFF5F0E6);
  static const muted = Color(0xFFAAA99F);
}

ThemeData buildRadiantTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: RadiantColors.gold,
        brightness: Brightness.dark,
        surface: RadiantColors.surface,
      ).copyWith(
        primary: RadiantColors.luminousGold,
        onPrimary: RadiantColors.voidBlack,
        secondary: RadiantColors.gold,
        onSurface: RadiantColors.ivory,
        surface: RadiantColors.surface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: RadiantColors.voidBlack,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: RadiantColors.ivory,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(
        color: RadiantColors.ivory,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: RadiantColors.ivory,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: RadiantColors.ivory, height: 1.5),
      bodyMedium: TextStyle(color: RadiantColors.muted, height: 1.45),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
    ),
  );
}
