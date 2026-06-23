import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';

class AppTheme {
  static const Color primary = Color(0xFF2D5A4A);
  static const Color primaryDark = Color(0xFF1E3D32);
  static const Color primaryLight = Color(0xFF3D7A64);
  static const Color secondary = Color(0xFFC4A77D);
  static const Color surface = Color(0xFFF8F6F3);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF8B5E3C);
  static const Color textPrimary = Color(0xFF1A2421);
  static const Color textSecondary = Color(0xFF5C6B66);
  static const Color textTertiary = Color(0xFF8A9691);
  static const Color border = Color(0xFFE2DDD6);
  static const Color borderLight = Color(0xFFF0EBE4);
  static const Color success = Color(0xFF2E7D5A);
  static const Color warning = Color(0xFFB8860B);
  static const Color destructive = Color(0xFFC62828);
  static const Color destructiveContainer = Color(0xFFFFEBEE);
  static const Color navBarBg = Color(0xFFFAFAF8);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8E8E2),
      onPrimaryContainer: primaryDark,
      secondary: secondary,
      onSecondary: textPrimary,
      secondaryContainer: const Color(0xFFF5EDE3),
      onSecondaryContainer: accent,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: borderLight,
      error: destructive,
      errorContainer: destructiveContainer,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceElevated,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: navBarBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.textTheme.labelMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTypography.textTheme.labelMedium;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: textSecondary.withValues(alpha: 0.85), size: 24);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTypography.textTheme.titleLarge,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: AppTypography.textTheme.bodyMedium,
        labelStyle: AppTypography.textTheme.labelMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: AppTypography.textTheme.labelMedium!,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.35)
              : border,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: textPrimary,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
