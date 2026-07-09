import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../screens/fullscreen_blueprint_screen.dart';
import '../../services/room_share_service.dart';
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
              Icon(Icons.architecture, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${design.name} • ${design.dimensions.width}×${design.dimensions.length} ft • '
                  '${design.furniture.length} furniture • '
                  '${design.wallTvUnits.length} wall TV',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              _BlueprintPremiumToggle(),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 18),
                tooltip: 'Full screen blueprint',
                onPressed: () => FullscreenBlueprintScreen.open(
                  context,
                  mode: FullscreenBlueprintMode.room,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                tooltip: 'Share room',
                onPressed: () => _shareRoom(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: () => _showHelp(context),
                tooltip: 'Help',
              ),
            ],
          ),
        ),
        const Expanded(child: BlueprintCanvas()),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              return Row(
                children: [
                  Expanded(
                    child: _BlueprintActionButton(
                      compact: compact,
                      onPressed: () => _showAddFurnitureSheet(context, ref),
                      icon: Icons.add,
                      label: 'Add Item',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _BlueprintActionButton(
                      compact: compact,
                      onPressed: () => _importRoom(context, ref),
                      icon: Icons.upload_file,
                      label: 'Import',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: compact ? 1 : 2,
                    child: _BlueprintActionButton(
                      compact: compact,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Preview3DScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      icon: Icons.view_in_ar,
                      label: 'Show 3D Model',
                      filled: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _shareRoom(BuildContext context, WidgetRef ref) async {
    final room = ref.read(roomDesignProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(roomShareServiceProvider).shareRoom(room);
    } on RoomShareException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not share room: $e')),
      );
    }
  }

  Future<void> _importRoom(BuildContext context, WidgetRef ref) async {
    final shareService = ref.read(roomShareServiceProvider);
    final project = ref.read(projectProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final imported = await shareService.pickAndImportRoom();
      if (!context.mounted) return;

      final asNewRoom = await showDialog<bool>(
        context: context,
        builder: (context) {
          final canAdd = project.canAddRoom;
          return AlertDialog(
            title: const Text('Import Room'),
            content: Text(
              'Import "${imported.name}" with ${imported.furniture.length} furniture items, '
              '${imported.doors.length} doors, and ${imported.windows.length} windows?\n\n'
              'Replace the current room, or add it as a separate room tab.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Replace current'),
              ),
              FilledButton(
                onPressed: canAdd ? () => Navigator.pop(context, true) : null,
                child: const Text('Add as new room'),
              ),
            ],
          );
        },
      );

      if (asNewRoom == null || !context.mounted) return;

      if (asNewRoom && !project.canAddRoom) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Maximum rooms reached. Replacing the current room instead.'),
          ),
        );
        ref.read(projectProvider.notifier).importSharedRoom(imported, asNewRoom: false);
      } else {
        ref.read(projectProvider.notifier).importSharedRoom(imported, asNewRoom: asNewRoom);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            asNewRoom && project.canAddRoom
                ? 'Room "${imported.name}" added'
                : 'Room "${imported.name}" loaded',
          ),
        ),
      );
    } on RoomShareException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not import room: $e')),
      );
    }
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
          'Tap "Show 3D Model" to see the realistic room with exact placement and sizes.\n\n'
          'Share exports a .ispace file (ZIP) with all textures and settings. '
          'Import accepts .ispace, .zip, or any room file from Interior Space.',
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

class _BlueprintActionButton extends StatelessWidget {
  const _BlueprintActionButton({
    required this.compact,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final bool compact;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = filled
        ? FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
          )
        : OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
          );

    final Widget button;
    if (compact) {
      button = filled
          ? FilledButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Icon(icon, size: 22),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Icon(icon, size: 22),
            );
    } else {
      button = filled
          ? FilledButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 18),
              label: Text(label),
            );
    }

    return Tooltip(message: label, child: button);
  }
}

class _BlueprintPremiumToggle extends ConsumerWidget {
  const _BlueprintPremiumToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumFurniture = ref.watch(premiumFurnitureProvider);
    final theme = Theme.of(context);

    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: premiumFurniture
          ? 'Disable premium blueprint furniture'
          : 'Enable premium blueprint furniture',
      onPressed: () {
        ref.read(premiumFurnitureProvider.notifier).state = !premiumFurniture;
      },
      icon: Icon(
        Icons.auto_awesome,
        size: 18,
        color: premiumFurniture
            ? Colors.amber.shade700
            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}
