import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/wall_tv_unit_config.dart';
import '../../providers/room_design_provider.dart';

class AddFurnitureSheet extends ConsumerWidget {
  const AddFurnitureSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(roomDesignProvider);
    final furniture = design.furniture;
    final wallTvUnits = design.wallTvUnits;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to Blueprint', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...FurnitureType.values.map((type) {
                  return ActionChip(
                    avatar: Icon(type.icon, size: 16),
                    label: Text(type.label),
                    onPressed: () {
                      ref.read(roomDesignProvider.notifier).addFurniture(type);
                    },
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.tv, size: 16),
                  label: const Text('Wall TV Unit'),
                  onPressed: () {
                    ref.read(roomDesignProvider.notifier).addWallTvUnit();
                  },
                ),
              ],
            ),
            if (furniture.isNotEmpty || wallTvUnits.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Placed Items', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...furniture.map((item) {
                    return InputChip(
                      avatar: Icon(item.type.icon, size: 16),
                      label: Text(FurnitureItem.displayLabel(furniture, item)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        ref.read(roomDesignProvider.notifier).removeFurniture(item.id);
                      },
                    );
                  }),
                  ...wallTvUnits.map((unit) {
                    return InputChip(
                      avatar: const Icon(Icons.tv, size: 16),
                      label: Text(WallTvUnitConfig.displayLabel(wallTvUnits, unit)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        ref.read(roomDesignProvider.notifier).removeWallTvUnit(unit.id);
                      },
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
