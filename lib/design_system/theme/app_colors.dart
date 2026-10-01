import 'package:flutter/material.dart';

/// Raw color tokens. Themes reference these; widgets use
/// `Theme.of(context).colorScheme` — never these directly.
///
/// Brand direction: "Ember" — an energetic orange tuned separately for
/// light (deeper, for contrast on white) and dark (brighter, for pop on
/// near-black, since most gym usage happens in dark environments).
abstract final class AppColors {
  // Brand
  static const Color emberLight = Color(0xFFC2410C);
  static const Color emberDark = Color(0xFFFF6B35);

  // Dark surfaces
  static const Color ink900 = Color(0xFF0C0D10);
  static const Color ink800 = Color(0xFF14161A);
  static const Color ink700 = Color(0xFF1B1E24);

  // Light neutrals
  static const Color paper = Color(0xFFFAFAF8);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
}
