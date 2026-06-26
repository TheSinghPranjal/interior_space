import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

class ItemEditorHeader extends StatelessWidget {
  const ItemEditorHeader({
    super.key,
    required this.title,
    required this.editingEnabled,
    required this.onToggleEdit,
    required this.onDelete,
    this.icon,
    this.expanded,
    this.onToggleExpand,
    this.expandAnimationDuration = const Duration(milliseconds: 340),
  });

  final String title;
  final IconData? icon;
  final bool editingEnabled;
  final VoidCallback onToggleEdit;
  final VoidCallback onDelete;
  final bool? expanded;
  final VoidCallback? onToggleExpand;
  final Duration expandAnimationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        if (onToggleExpand != null && expanded != null)
          IconButton(
            icon: AnimatedRotation(
              turns: expanded! ? 0.5 : 0,
              duration: expandAnimationDuration,
              curve: Curves.easeInOutCubic,
              child: const Icon(Icons.keyboard_arrow_down, size: 20),
            ),
            tooltip: expanded! ? 'Collapse' : 'Expand',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onPressed: onToggleExpand,
          ),
        IconButton(
          icon: Icon(
            editingEnabled ? Icons.edit_off_outlined : Icons.edit_outlined,
            size: 18,
          ),
          tooltip: editingEnabled ? 'Lock parameters' : 'Edit parameters',
          style: IconButton.styleFrom(
            foregroundColor: editingEnabled ? AppTheme.warning : theme.colorScheme.primary,
            backgroundColor: editingEnabled
                ? AppTheme.warning.withValues(alpha: 0.12)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          ),
          onPressed: onToggleEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Delete',
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.destructive,
            backgroundColor: AppTheme.destructiveContainer.withValues(alpha: 0.6),
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
