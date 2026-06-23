import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../models/apartment_layout.dart';
import '../../providers/apartment_placement_history_provider.dart';
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
    final history = ref.watch(apartmentPlacementHistoryProvider);
    final rooms = project.roomsForActiveApartment;
    final layout = project.apartmentLayout;
    final theme = Theme.of(context);
    final historyNotifier = ref.read(apartmentPlacementHistoryProvider.notifier);

    void undoMove() {
      if (history.canUndo) historyNotifier.undo();
    }

    void redoMove() {
      if (history.canRedo) historyNotifier.redo();
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undoMove,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undoMove,
        const SingleActivator(LogicalKeyboardKey.keyZ, shift: true, control: true): redoMove,
        const SingleActivator(LogicalKeyboardKey.keyZ, shift: true, meta: true): redoMove,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): redoMove,
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): redoMove,
      },
      child: Focus(
        autofocus: true,
        child: Column(
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
                Text('Your Rooms — ${layout.name}', style: theme.textTheme.titleSmall),
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
                _ApartmentSizeControls(
                  layout: layout,
                  canUndo: history.canUndo,
                  canRedo: history.canRedo,
                  onUndo: undoMove,
                  onRedo: redoMove,
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
                    'Apartment Blueprint • ${layout.name} • ${layout.placements.length} rooms placed • '
                    '${layout.widthFt.toStringAsFixed(0)}×${layout.lengthFt.toStringAsFixed(0)} ft',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                _ApartmentUndoRedoButtons(
                  canUndo: history.canUndo,
                  canRedo: history.canRedo,
                  onUndo: undoMove,
                  onRedo: redoMove,
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
        ),
      ),
    );
  }
}

class _ApartmentSizeControls extends ConsumerStatefulWidget {
  const _ApartmentSizeControls({
    required this.layout,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final ApartmentLayout layout;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  ConsumerState<_ApartmentSizeControls> createState() => _ApartmentSizeControlsState();
}

class _ApartmentSizeControlsState extends ConsumerState<_ApartmentSizeControls> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Apartment Size', style: theme.textTheme.titleSmall),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: _expanded ? 'Hide apartment size' : 'Show apartment size',
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 22),
              ),
            ),
            _ApartmentUndoRedoButtons(
              canUndo: widget.canUndo,
              canRedo: widget.canRedo,
              onUndo: widget.onUndo,
              onRedo: widget.onRedo,
            ),
          ],
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeIn,
          sizeCurve: Curves.easeInOut,
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              DimensionControl(
                label: 'Width',
                value: widget.layout.widthFt,
                min: RoomConstants.minApartmentWidth,
                max: RoomConstants.maxApartmentWidth,
                onChanged: (v) => ref
                    .read(projectProvider.notifier)
                    .updateApartmentDimensions(widthFt: v),
              ),
              DimensionControl(
                label: 'Length',
                value: widget.layout.lengthFt,
                min: RoomConstants.minApartmentLength,
                max: RoomConstants.maxApartmentLength,
                onChanged: (v) => ref
                    .read(projectProvider.notifier)
                    .updateApartmentDimensions(lengthFt: v),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ApartmentUndoRedoButtons extends StatelessWidget {
  const _ApartmentUndoRedoButtons({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.undo, color: canUndo ? null : Colors.grey.shade400),
          tooltip: 'Undo move',
          onPressed: canUndo ? onUndo : null,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.redo, color: canRedo ? null : Colors.grey.shade400),
          tooltip: 'Redo move',
          onPressed: canRedo ? onRedo : null,
        ),
      ],
    );
  }
}
