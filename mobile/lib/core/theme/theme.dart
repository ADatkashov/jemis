import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: JemisColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF7FD08F) : JemisColors.primaryStrong,
    onPrimary: dark ? const Color(0xFF0B2B15) : Colors.white,
    primaryContainer: dark ? const Color(0xFF27402B) : JemisColors.lime,
    onPrimaryContainer: dark ? JemisColors.darkText : JemisColors.deep,
    secondary: JemisColors.accent,
    onSecondary: JemisColors.text,
    surface: dark ? JemisColors.darkSurface : JemisColors.surface,
    onSurface: dark ? JemisColors.darkText : JemisColors.text,
    onSurfaceVariant: dark ? JemisColors.darkTextSecondary : JemisColors.textSecondary,
    error: dark ? const Color(0xFFF2B8B5) : JemisColors.error,
    outline: dark ? const Color(0xFF2C362C) : JemisColors.outline,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? JemisColors.darkBackground : JemisColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? JemisColors.darkBackground : JemisColors.background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
        side: BorderSide(color: scheme.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
        borderSide: BorderSide(color: scheme.outline),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.chip)),
      side: BorderSide(color: scheme.outline),
    ),
    textTheme: base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
