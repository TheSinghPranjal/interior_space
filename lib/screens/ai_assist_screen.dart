import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

class AiAssistPlaceholder extends StatelessWidget {
  const AiAssistPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 54,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'AI Design Assistant',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  'Coming soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Smart suggestions for colors, materials, furniture layout, '
                'and full room makeovers — powered by AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Assist will be available in a future update'),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 16),
                label: const Text('Notify me when ready'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
