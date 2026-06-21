import 'package:flutter/material.dart';

import 'app_theme.dart';

abstract final class AppTypography {
  static TextTheme textTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppTheme.textPrimary,
    ),
    headlineMedium: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppTheme.textPrimary,
    ),
    titleLarge: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppTheme.textPrimary,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppTheme.textSecondary,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppTheme.textPrimary,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppTheme.textSecondary,
    ),
  );
}
