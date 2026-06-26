import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

enum PlacedItemConfigAction { copy, paste }

class PlacedItemConfigMenu extends ConsumerWidget {
  const PlacedItemConfigMenu({
    super.key,
    required this.onCopy,
    required this.showPaste,
    required this.onPaste,
    this.pasteLabel,
  });

  final VoidCallback onCopy;
  final bool showPaste;
  final VoidCallback onPaste;
  final String? pasteLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return PopupMenuButton<PlacedItemConfigAction>(
      tooltip: 'Configuration options',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurfaceVariant),
      onSelected: (action) {
        switch (action) {
          case PlacedItemConfigAction.copy:
            onCopy();
          case PlacedItemConfigAction.paste:
            onPaste();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: PlacedItemConfigAction.copy,
          child: ListTile(
            leading: Icon(Icons.copy_outlined, size: 20),
            title: Text('Copy configuration'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (showPaste)
          PopupMenuItem(
            value: PlacedItemConfigAction.paste,
            child: ListTile(
              leading: Icon(Icons.content_paste_outlined, size: 20, color: AppTheme.primary),
              title: Text(pasteLabel ?? 'Paste configuration'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );
  }
}

void showPlacedItemConfigSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
