import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/room_design_provider.dart';
import '../../screens/preview_3d_screen.dart';
import 'add_furniture_sheet.dart';
import 'blueprint_canvas.dart';

class BlueprintView extends ConsumerWidget {
  const BlueprintView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              const Icon(Icons.architecture, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${design.dimensions.width}×${design.dimensions.length} ft • '
                  '${design.furniture.length} furniture • '
                  '${design.cupboards.length} cupboards',
                  style: const TextStyle(fontSize: 13),
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
          padding: const EdgeInsets.all(16),
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
          'Place beds, wardrobes, and cupboards on the floor plan by dragging them. '
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
