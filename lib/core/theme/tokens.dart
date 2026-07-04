// File: lib/core/theme/tokens.dart
// App: Enthusia
// Description: Design tokens — single source of truth for all colors,
// spacing, typography, and other design constants used across the app.
// Every widget imports from here. Never hardcode hex values elsewhere.

import 'package:flutter/material.dart';

/// All brand and semantic colors used in Enthusia.
/// Names match the Figma variables exactly.
class AppColors {
  // Brand
  static const Color primary = Color(
    0xFF1E4DEE,
  ); // Splash blue, primary CTA bg, h1
  static const Color primaryStroke = Color(
    0xFF1943EA,
  ); // 3px border on primary buttons
  static const Color active = Color(
    0xFF3262F2,
  ); // active borders, nav underline
  static const Color accent = Color(
    0xFF4F67FF,
  ); // add task text, calendar active day

  // Text
  static const Color headingDark = Color(0xFF18181B); // h2, screen titles
  static const Color headingMid = Color(0xFF525254); // subheadings
  static const Color onPrimary = Color(0xFFF9FAFB); // text on blue buttons
  static const Color placeholder = Color(0xFFC3C3C4); // input placeholders
  static const Color muted = Color(
    0xFFA1A1AA,
  ); // secondary labels, "3 of 4 done"

  // Surfaces
  static const Color background = Color(0xFFFBFCFF); // page background
  static const Color card = Color(0xFFFFFFFF); // card / container background
  static const Color onboarding = Color(
    0xFFF2F2F2,
  ); // onboarding screen background

  // Borders
  static const Color border = Color(0xFFE4E4E7); // 1px dividers, input borders

  // Status
  static const Color success = Color(0xFF16A34A); // completed task green
  static const Color successBackground = Color(0xFFE9FFF1); // success state bg
  static const Color error = Color(0xFFDC2626); // validation errors
  // Onboarding-specific (green check badge)
  static const Color checkBadge = Color(0xFF0BD354);
  static const Color checkBadgeBorder = Color(0xFF25AF58);
  // Streak
  static const Color streakForeground = Color(
    0xFFEB5757,
  ); // fire icon, active streak
  static const Color streakBackground = Color(0xFFFFFAEE); // streak badge bg
  static const Color streakNumber = Color(0xFFDB0000); // big streak count
  static const Color streakBroken = Color(
    0xFFF25959,
  ); // broken streak indicator
  static const Color streakLostBackground = Color(0xFFFDD2E7); // lost streak bg
  static const Color streakLongestBorder = Color(
    0xFF5D09E4,
  ); // longest streak record border
}

/// Spacing scale — strict 8-point system.
/// Use these constants instead of raw numbers like 16, 24, etc.
class AppSpacing {
  static const double xs = 4; // tight icon padding
  static const double s = 8; // base unit
  static const double sm = 12; // half-step, inline gaps
  static const double m = 16; // screen side padding, card padding
  static const double l = 24; // section spacing inside cards
  static const double xl = 32; // between major sections
  static const double xxl = 48; // top-level vertical rhythm
  static const double xxxl = 64; // hero spacing

  /// Standard side padding on every screen.
  static const double screenPadding = m;
}

/// Border radius scale.
class AppRadius {
  static const double sm = 8; // chips, tags
  static const double md = 12; // inputs, secondary buttons
  static const double lg = 16; // cards, modals, list items
  static const double pill = 64; // primary CTA only — fully rounded
}

/// Border width tokens.
class AppBorderWidth {
  static const double standard = 1; // standard 1px borders
  static const double cta = 3; // primary CTA stroke
}

/// Typography tokens. Font family is Inter everywhere.
/// Use these via AppTextStyles below — don't hardcode in widgets.
class AppFontSize {
  static const double h1 = 32;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double body = 16;
  static const double caption = 14;
  static const double micro = 12;
}

class AppLineHeight {
  static const double h1 = 40;
  static const double h2 = 32;
  static const double h3 = 28;
  static const double body = 24;
  static const double caption = 20;
  static const double micro = 16;
}

/// Pre-built TextStyle presets. Use these in widgets instead of building
/// TextStyle objects from scratch every time.
class AppTextStyles {
  static const String _fontFamily = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.h1,
    fontWeight: FontWeight.w700,
    height: AppLineHeight.h1 / AppFontSize.h1,
    color: AppColors.headingDark,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.h2,
    fontWeight: FontWeight.w700,
    height: AppLineHeight.h2 / AppFontSize.h2,
    color: AppColors.headingDark,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.h3,
    fontWeight: FontWeight.w600,
    height: AppLineHeight.h3 / AppFontSize.h3,
    color: AppColors.headingDark,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.body,
    fontWeight: FontWeight.w400,
    height: AppLineHeight.body / AppFontSize.body,
    color: AppColors.headingDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.body,
    fontWeight: FontWeight.w500,
    height: AppLineHeight.body / AppFontSize.body,
    color: AppColors.headingDark,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.caption,
    fontWeight: FontWeight.w400,
    height: AppLineHeight.caption / AppFontSize.caption,
    color: AppColors.headingMid,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppFontSize.micro,
    fontWeight: FontWeight.w500,
    height: AppLineHeight.micro / AppFontSize.micro,
    color: AppColors.muted,
  );
}
