import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/room_design_provider.dart';
import '../../screens/preview_3d_screen.dart';
import 'add_furniture_sheet.dart';
import 'blueprint_canvas.dart';

class BlueprintView extends ConsumerWidget {
  const BlueprintView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);

    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.architecture, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${design.name} • ${design.dimensions.width}×${design.dimensions.length} ft • '
                  '${design.furniture.length} furniture • '
                  '${design.cupboards.length} cupboards',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showHelp(context),
                tooltip: 'Help',
              ),
            ],
          ),
        ),
        const Expanded(child: BlueprintCanvas()),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddFurnitureSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Preview3DScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('Show 3D Model'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blueprint Mode'),
        content: const Text(
          'Pinch with two fingers to zoom the blueprint. '
          'Press and hold furniture, doors, windows, or wall TV units to select them, then drag to move. '
          'While selected, use the rotate buttons above the item to turn it. '
          'Adjust dimensions via the Design menu (tune icon). '
          'Tap "Show 3D Model" to see the realistic room with exact placement and sizes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showAddFurnitureSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddFurnitureSheet(),
    );
  }
}
