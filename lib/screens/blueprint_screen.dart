import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../providers/room_design_provider.dart';
import '../widgets/blueprint/blueprint_canvas.dart';
import 'preview_3d_screen.dart';

class BlueprintScreen extends ConsumerWidget {
  const BlueprintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Column(
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
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blueprint Mode'),
        content: const Text(
          'Place beds, wardrobes, and cupboards on the floor plan by dragging them. '
          'Adjust dimensions in the Furniture or Cupboards tabs. '
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to Blueprint', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...FurnitureType.values.map((type) {
                    return ActionChip(
                      avatar: Icon(type.icon, size: 18),
                      label: Text(type.label),
                      onPressed: () {
                        ref.read(roomDesignProvider.notifier).addFurniture(type);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(roomDesignProvider.notifier).addCupboard();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.kitchen),
                label: const Text('Add Cupboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
