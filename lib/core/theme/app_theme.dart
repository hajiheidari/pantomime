import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cheerful cartoon palette. Dark, saturated background for high contrast in
/// dim rooms; bright fills with thick dark outlines for everything tappable.
abstract final class AppColors {
  static const background = Color(0xFF2A1B5C);
  static const backgroundDeep = Color(0xFF1A0F3D);
  static const surface = Color(0xFF3B2A7A);
  static const outline = Color(0xFF120A2B);
  static const ink = Color(0xFF120A2B);
  static const text = Colors.white;
  static const textMuted = Color(0xFFCBC2F2);

  static const yellow = Color(0xFFFFD23F);
  static const pink = Color(0xFFFF5C9A);
  static const cyan = Color(0xFF3BCEF5);
  static const green = Color(0xFF3DDC84);
  static const orange = Color(0xFFFF8A3D);
  static const red = Color(0xFFFF4D5A);
  static const purple = Color(0xFF9B6BFF);
  static const lime = Color(0xFFB8F25A);
  static const card = Color(0xFFFFF8E7);
}

/// Colour + avatar of each team (by index).
class TeamStyle {
  const TeamStyle(this.color, this.emoji);

  final Color color;
  final String emoji;

  static const all = [
    TeamStyle(AppColors.pink, '🦊'),
    TeamStyle(AppColors.cyan, '🐼'),
    TeamStyle(AppColors.green, '🐸'),
    TeamStyle(AppColors.yellow, '🐯'),
    TeamStyle(AppColors.purple, '🐨'),
    TeamStyle(AppColors.orange, '🦁'),
    TeamStyle(AppColors.red, '🐙'),
    TeamStyle(AppColors.lime, '🐵'),
  ];

  static TeamStyle of(int index) => all[index % all.length];
}

const appFontFamily = 'Vazirmatn';

/// Web only: Flutter draws text itself there and would download emoji fonts
/// from fonts.gstatic.com (offline: none; Iran: maybe blocked). The bundled
/// subset (tool/subset_emoji.py) covers every emoji the app uses. Native
/// builds keep the system's emoji.
const appFontFallback = kIsWeb ? ['EmojiSubset'] : null;

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: appFontFamily,
    fontFamilyFallback: appFontFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.dark,
      primary: AppColors.yellow,
      onPrimary: AppColors.ink,
      secondary: AppColors.pink,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFallback,
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.text,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.ink
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.green
            : AppColors.backgroundDeep,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.outline),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      titleTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        fontSize: 16,
        color: AppColors.ink,
        height: 1.6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.outline, width: 3),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.yellow,
      contentTextStyle: TextStyle(
        fontFamily: appFontFamily,
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Background gradient used on every screen.
const appBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.backgroundDeep],
  ),
);
