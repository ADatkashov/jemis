import 'package:flutter/material.dart';

/// JEMIS design tokens. Contrast was checked against WCAG 2.1 AA:
/// white on [primaryStrong] 5.39:1, [textSecondary] on white 5.78:1, error on white 6.54:1.
/// The brand green #27883F (4.49:1 with white) is used for decoration and large elements only.
class JemisColors {
  static const primary = Color(0xFF27883F);
  static const primaryStrong = Color(0xFF1F7A38);
  static const deep = Color(0xFF174A2A);
  static const lime = Color(0xFFDDF1B8);
  static const background = Color(0xFFF7F9F3);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF202820);
  static const textSecondary = Color(0xFF5F685F);
  static const accent = Color(0xFFFFD23F);
  static const error = Color(0xFFB3261E);
  static const outline = Color(0xFFDFE5DA);

  static const darkBackground = Color(0xFF121712);
  static const darkSurface = Color(0xFF1B221B);
  static const darkText = Color(0xFFEEF3EA);
  static const darkTextSecondary = Color(0xFFA8B2A6);
}

/// 4/8 dp spacing grid.
class Space {
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32;
}

class Radii {
  static const double card = 16, chip = 12, button = 14, sheet = 20;
}
