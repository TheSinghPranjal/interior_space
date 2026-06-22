import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../providers/project_provider.dart';
import '../common/dimension_control.dart';
import '../../screens/preview_3d_screen.dart';
import 'apartment_canvas.dart';

class ApartmentSpaceView extends ConsumerWidget {
  const ApartmentSpaceView({super.key, this.showBlueprintOnly = false});

  final bool showBlueprintOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final rooms = project.roomsOrDefault;
    final layout = project.apartmentLayout;
    final theme = Theme.of(context);

    return Column(
      children: [
        if (!showBlueprintOnly)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apartment, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arrange rooms on the floor plan. Switch to Interior Space to edit a room.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Your Rooms', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final onBlueprint =
                          layout.placements.where((p) => p.roomId == room.id).length;
                      return Container(
                        padding: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: onBlueprint > 0
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.meeting_room, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(room.name, style: theme.textTheme.labelMedium),
                                  if (onBlueprint > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '($onBlueprint)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22),
                              tooltip: 'Add to blueprint',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                ref.read(projectProvider.notifier).addRoomToApartment(room.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (layout.placements.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${layout.placements.length} room(s) on blueprint • Long-press to move',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Apartment Size', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                DimensionControl(
                  label: 'Width',
                  value: layout.widthFt,
                  min: RoomConstants.minApartmentWidth,
                  max: RoomConstants.maxApartmentWidth,
                  onChanged: (v) => ref
                      .read(projectProvider.notifier)
                      .updateApartmentDimensions(widthFt: v),
                ),
                DimensionControl(
                  label: 'Length',
                  value: layout.lengthFt,
                  min: RoomConstants.minApartmentLength,
                  max: RoomConstants.maxApartmentLength,
                  onChanged: (v) => ref
                      .read(projectProvider.notifier)
                      .updateApartmentDimensions(lengthFt: v),
                ),
              ],
            ),
          ),
        if (showBlueprintOnly)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.architecture, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Apartment Blueprint • ${layout.placements.length} rooms placed • '
                    '${layout.widthFt.toStringAsFixed(0)}×${layout.lengthFt.toStringAsFixed(0)} ft',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const Expanded(child: ApartmentCanvas()),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: layout.placements.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Preview3DScreen(apartmentMode: true),
                        fullscreenDialog: true,
                      ),
                    );
                  },
            icon: const Icon(Icons.view_in_ar),
            label: const Text('Show Apartment 3D'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}
