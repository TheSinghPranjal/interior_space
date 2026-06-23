import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project_design.dart';
import '../../providers/project_provider.dart';
import '../common/confirm_delete_dialog.dart';

class RoomTabsBar extends ConsumerWidget {
  const RoomTabsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final rooms = project.roomsForActiveApartment;
    final activeRoom = project.activeRoom;
    final activeIndex = rooms.indexWhere((r) => r.id == activeRoom.id);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: rooms.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final isActive = index == activeIndex;
                  return _RoomTab(
                    label: room.name,
                    isActive: isActive,
                    canDelete: project.canRemoveRoom,
                    onTap: () =>
                        ref.read(projectProvider.notifier).setActiveRoom(index),
                    onDelete: () => _confirmDeleteRoom(context, ref, index, room.name),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: project.canAddRoom
                    ? 'Add room (${project.roomsOrDefault.length}/${ProjectDesign.maxRooms})'
                    : 'Maximum ${ProjectDesign.maxRooms} rooms',
                onPressed: project.canAddRoom
                    ? () => ref.read(projectProvider.notifier).addRoom()
                    : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: project.canAddRoom
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRoom(
    BuildContext context,
    WidgetRef ref,
    int index,
    String roomName,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Room?',
      message: 'Remove "$roomName" and all its customizations? This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;
    ref.read(projectProvider.notifier).removeRoom(index);
  }
}

class _RoomTab extends StatelessWidget {
  const _RoomTab({
    required this.label,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: canDelete ? 4 : 14,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.meeting_room,
                size: 14,
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: isActive
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
