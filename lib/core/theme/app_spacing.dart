import 'package:flutter/material.dart';

/// Consistent spacing scale for a polished SaaS-style layout.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: lg);
}
