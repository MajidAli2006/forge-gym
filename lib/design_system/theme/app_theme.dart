import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/theme/app_colors.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Light and dark themes for the app.
///
/// Built from [AppColors] tokens + [AppTextStyles]; screens and components
/// read from the theme and never hardcode colors or text styles.
abstract final class AppTheme {
  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.emberLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE3D3),
    onPrimaryContainer: Color(0xFF4A1F04),
    secondary: Color(0xFF46525F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8EF),
    onSecondaryContainer: Color(0xFF1B222B),
    tertiary: Color(0xFF0E7C5B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC9F2E2),
    onTertiaryContainer: Color(0xFF063B2B),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF17191D),
    surfaceDim: Color(0xFFE8EAED),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F5F6),
    surfaceContainer: Color(0xFFEEEFF1),
    surfaceContainerHigh: Color(0xFFE8EAED),
    surfaceContainerHighest: Color(0xFFDFE2E6),
    onSurfaceVariant: Color(0xFF5A636E),
    outline: Color(0xFFC9CFD6),
    outlineVariant: Color(0xFFE2E5E9),
    inverseSurface: Color(0xFF17191D),
    onInverseSurface: Color(0xFFF4F5F6),
    inversePrimary: Color(0xFFFFB48A),
    surfaceTint: AppColors.emberLight,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.emberDark,
    onPrimary: Color(0xFF2A1000),
    primaryContainer: Color(0xFF5C2508),
    onPrimaryContainer: Color(0xFFFFE3D3),
    secondary: Color(0xFFB9C2CD),
    onSecondary: Color(0xFF1B222B),
    secondaryContainer: Color(0xFF333C47),
    onSecondaryContainer: Color(0xFFE2E8EF),
    tertiary: Color(0xFF4ADE9E),
    onTertiary: Color(0xFF063B2B),
    tertiaryContainer: Color(0xFF0B4A34),
    onTertiaryContainer: Color(0xFFC9F2E2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.ink900,
    onSurface: Color(0xFFF4F5F6),
    surfaceDim: AppColors.ink900,
    surfaceBright: Color(0xFF2A2E35),
    surfaceContainerLowest: Color(0xFF060708),
    surfaceContainerLow: AppColors.ink800,
    surfaceContainer: AppColors.ink700,
    surfaceContainerHigh: Color(0xFF262B33),
    surfaceContainerHighest: Color(0xFF31373F),
    onSurfaceVariant: Color(0xFFA7B0BC),
    outline: Color(0xFF4A525C),
    outlineVariant: Color(0xFF2A3038),
    inverseSurface: Color(0xFFF4F5F6),
    onInverseSurface: Color(0xFF17191D),
    inversePrimary: AppColors.emberLight,
    surfaceTint: AppColors.emberDark,
  );

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.headline,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.subtitle,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.caption,
      labelSmall: AppTextStyles.caption,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    ButtonStyle buttonStyle(double minHeight) => ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(64, minHeight)),
      textStyle: const WidgetStatePropertyAll(AppTextStyles.button),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headline.copyWith(
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.caption.copyWith(color: scheme.onSurface),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle(56)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle(56)),
      textButtonTheme: TextButtonThemeData(style: buttonStyle(48)),
    );
  }
}
