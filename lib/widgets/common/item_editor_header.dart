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
  });

  final String title;
  final IconData? icon;
  final bool editingEnabled;
  final VoidCallback onToggleEdit;
  final VoidCallback onDelete;

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
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        IconButton(
          icon: Icon(
            editingEnabled ? Icons.edit_off_outlined : Icons.edit_outlined,
            size: 20,
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
          icon: const Icon(Icons.delete_outline, size: 20),
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
