import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Branded logo mark used on splash screen and app chrome.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.showLabel = true,
    this.compact = false,
  });

  final double size;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? size * 0.55 : size * 0.45;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.view_in_ar_rounded,
                size: iconSize,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              Positioned(
                bottom: size * 0.18,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.06,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: compact ? 8 : 16),
          Text(
            'Abode',
            style: TextStyle(
              fontSize: compact ? 18 : 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          if (!compact)
            Text(
              'Professional Room Designer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary.withValues(alpha: 0.9),
              ),
            ),
        ],
      ],
    );
  }
}
