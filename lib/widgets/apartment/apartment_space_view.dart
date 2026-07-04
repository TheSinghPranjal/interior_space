import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/room_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/apartment_layout.dart';
import '../../models/room_design.dart';
import '../../screens/fullscreen_blueprint_screen.dart';
import '../../providers/apartment_blueprint_selection_provider.dart';
import '../../providers/apartment_placement_history_provider.dart';
import '../../providers/project_provider.dart';
import '../../services/apartment_share_service.dart';
import '../common/dimension_control.dart';
import 'apartment_details_dialog.dart';
import 'apartment_canvas.dart';

class ApartmentSpaceView extends ConsumerWidget {
  const ApartmentSpaceView({super.key, this.showBlueprintOnly = false});

  final bool showBlueprintOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final history = ref.watch(apartmentPlacementHistoryProvider);
    final selectedPlacementIds = ref.watch(apartmentBlueprintSelectionProvider);
    final rooms = project.roomsForActiveApartment;
    final layout = project.apartmentLayout;
    final theme = Theme.of(context);
    final historyNotifier = ref.read(apartmentPlacementHistoryProvider.notifier);
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (showBlueprintOnly) {
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
                            'Apartment Blueprint • ${layout.name} • ${layout.placements.length} rooms placed • '
                            '${layout.widthFt.toStringAsFixed(0)}×${layout.lengthFt.toStringAsFixed(0)} ft',
                            style: theme.textTheme.bodySmall,
                            maxLines: isLandscape ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _ApartmentBlueprintToolbar(
                          canUndo: history.canUndo,
                          canRedo: history.canRedo,
                          onUndo: undoMove,
                          onRedo: redoMove,
                          onFullscreen: () => FullscreenBlueprintScreen.open(
                            context,
                            mode: FullscreenBlueprintMode.apartment,
                          ),
                          onShare: () => _shareApartment(context, ref),
                          selectedCount: selectedPlacementIds.length,
                          allSelected: layout.placements.isNotEmpty &&
                              selectedPlacementIds.length == layout.placements.length,
                          onSelectAll: layout.placements.isEmpty
                              ? null
                              : () {
                                  ref
                                      .read(apartmentBlueprintSelectionProvider.notifier)
                                      .selectAll(layout.placements.map((p) => p.id));
                                },
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: ApartmentCanvas()),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _importApartment(context, ref),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import Apartment'),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ApartmentHeaderPanel(
                    layout: layout,
                    rooms: rooms,
                    hideIntro: isLandscape,
                    canUndo: history.canUndo,
                    canRedo: history.canRedo,
                    onUndo: undoMove,
                    onRedo: redoMove,
                    onAddRoom: (roomId) {
                      ref.read(projectProvider.notifier).addRoomToApartment(roomId);
                    },
                  ),
                  _ApartmentFloorPlanCard(layout: layout),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareApartment(BuildContext context, WidgetRef ref) async {
    final project = ref.read(projectProvider);
    final layout = project.apartmentLayout;
    final rooms = project.roomsForActiveApartment;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(apartmentShareServiceProvider).shareApartment(
            apartment: layout,
            rooms: rooms,
          );
    } on ApartmentShareException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export apartment: $e')),
      );
    }
  }

  Future<void> _importApartment(BuildContext context, WidgetRef ref) async {
    final shareService = ref.read(apartmentShareServiceProvider);
    final project = ref.read(projectProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final imported = await shareService.pickAndImportApartment();
      if (!context.mounted) return;

      final roomCount = imported.rooms.length;
      final furnitureCount =
          imported.rooms.fold<int>(0, (sum, room) => sum + room.furniture.length);
      final asNewApartment = await showDialog<bool>(
        context: context,
        builder: (context) {
          final canAdd = project.canAddApartment;
          return AlertDialog(
            title: const Text('Import Apartment'),
            content: Text(
              'Import "${imported.apartment.name}" with $roomCount room(s), '
              '$furnitureCount furniture items, and '
              '${imported.apartment.placements.length} blueprint placement(s)?\n\n'
              'Replace the current apartment, or add it as a separate apartment tab.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Replace current'),
              ),
              FilledButton(
                onPressed: canAdd ? () => Navigator.pop(context, true) : null,
                child: const Text('Add as new apartment'),
              ),
            ],
          );
        },
      );

      if (asNewApartment == null || !context.mounted) return;

      if (asNewApartment && !project.canAddApartment) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum apartments reached. Replacing the current apartment instead.',
            ),
          ),
        );
        ref.read(projectProvider.notifier).importSharedApartment(
              apartment: imported.apartment,
              rooms: imported.rooms,
              asNewApartment: false,
            );
      } else {
        ref.read(projectProvider.notifier).importSharedApartment(
              apartment: imported.apartment,
              rooms: imported.rooms,
              asNewApartment: asNewApartment,
            );
      }

      ref.read(apartmentPlacementHistoryProvider.notifier).clear();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            asNewApartment && project.canAddApartment
                ? 'Apartment "${imported.apartment.name}" added'
                : 'Apartment "${imported.apartment.name}" loaded',
          ),
        ),
      );
    } on ApartmentShareException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not import apartment: $e')),
      );
    }
  }
}

class _ApartmentFloorPlanCard extends StatelessWidget {
  const _ApartmentFloorPlanCard({required this.layout});

  final ApartmentLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.55)),
          boxShadow: AppSpacing.cardShadow(context),
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.grid_on, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Apartment floor plan',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${layout.widthFt.toStringAsFixed(0)}×${layout.lengthFt.toStringAsFixed(0)} ft',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Long-press a room to move it • Pinch to zoom • Select multiple to move together',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final aspect = layout.widthFt / layout.lengthFt;
                  final height = (constraints.maxWidth / aspect).clamp(280.0, 520.0);

                  return SizedBox(
                    height: height,
                    width: double.infinity,
                    child: const ApartmentCanvas(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApartmentHeaderPanel extends StatelessWidget {
  const _ApartmentHeaderPanel({
    required this.layout,
    required this.rooms,
    required this.hideIntro,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onAddRoom,
  });

  final ApartmentLayout layout;
  final List<RoomDesign> rooms;
  final bool hideIntro;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final ValueChanged<String> onAddRoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.55)),
          boxShadow: AppSpacing.cardShadow(context),
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hideIntro)
                Row(
                  children: [
                    Icon(Icons.apartment, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Arrange rooms on the floor plan. Switch to Interior Space to edit a room.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              if (!hideIntro) const SizedBox(height: AppSpacing.sm),
              Text('Your Rooms — ${layout.name}', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.meeting_room,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(room.name, style: theme.textTheme.labelLarge),
                                if (onBlueprint > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '($onBlueprint)',
                                    style: TextStyle(
                                      fontSize: 12,
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
                            visualDensity: VisualDensity.standard,
                            onPressed: () => onAddRoom(room.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (layout.placements.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${layout.placements.length} room(s) on blueprint',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: const Divider(height: 1),
              ),
              const SizedBox(height: AppSpacing.md - 4),
              _ApartmentSizeControls(
                layout: layout,
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: onUndo,
                onRedo: onRedo,
              ),
            ],
          ),
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
  late bool _expanded;
  bool _editingEnabled = false;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Apartment Size', style: theme.textTheme.titleSmall),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Apartment information',
              icon: Icon(
                Icons.info_outline,
                size: 18,
                color: widget.layout.details.hasAny
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: () => showApartmentDetailsDialog(context),
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: _editingEnabled ? 'Lock apartment size' : 'Edit apartment size',
              icon: Icon(
                _editingEnabled ? Icons.edit_off_outlined : Icons.edit_outlined,
                size: 18,
              ),
              style: IconButton.styleFrom(
                foregroundColor:
                    _editingEnabled ? AppTheme.warning : theme.colorScheme.primary,
                backgroundColor: _editingEnabled
                    ? AppTheme.warning.withValues(alpha: 0.12)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              ),
              onPressed: () => setState(() => _editingEnabled = !_editingEnabled),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: _expanded ? 'Hide apartment size' : 'Show apartment size',
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20),
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
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: _expanded
              ? Column(
                  key: const ValueKey('apartment-size-expanded'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const _ApartmentNameField(),
                    const SizedBox(height: AppSpacing.sm),
                    if (!_editingEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          'Tap edit to adjust width and length.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    DimensionControl(
                      label: 'Width',
                      value: widget.layout.widthFt,
                      min: RoomConstants.minApartmentWidth,
                      max: RoomConstants.maxApartmentWidth,
                      enabled: _editingEnabled,
                      onChanged: (v) => ref
                          .read(projectProvider.notifier)
                          .updateApartmentDimensions(widthFt: v),
                    ),
                    DimensionControl(
                      label: 'Length',
                      value: widget.layout.lengthFt,
                      min: RoomConstants.minApartmentLength,
                      max: RoomConstants.maxApartmentLength,
                      enabled: _editingEnabled,
                      onChanged: (v) => ref
                          .read(projectProvider.notifier)
                          .updateApartmentDimensions(lengthFt: v),
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ApartmentNameField extends ConsumerStatefulWidget {
  const _ApartmentNameField();

  @override
  ConsumerState<_ApartmentNameField> createState() => _ApartmentNameFieldState();
}

class _ApartmentNameFieldState extends ConsumerState<_ApartmentNameField> {
  TextEditingController? _controller;
  int? _trackedApartmentIndex;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(projectProvider).apartmentLayout;
    final apartmentIndex = ref.watch(projectProvider).safeActiveApartmentIndex;

    _controller ??= TextEditingController(text: layout.name);
    _trackedApartmentIndex ??= apartmentIndex;

    if (_trackedApartmentIndex != apartmentIndex) {
      _trackedApartmentIndex = apartmentIndex;
      _controller!
        ..text = layout.name
        ..selection = TextSelection.collapsed(offset: layout.name.length);
    }

    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: 'Apartment Name'),
      onChanged: ref.read(projectProvider.notifier).updateApartmentName,
    );
  }
}

class _ApartmentBlueprintToolbar extends StatelessWidget {
  const _ApartmentBlueprintToolbar({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onFullscreen,
    required this.onShare,
    required this.selectedCount,
    required this.allSelected,
    required this.onSelectAll,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onFullscreen;
  final VoidCallback onShare;
  final int selectedCount;
  final bool allSelected;
  final VoidCallback? onSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.28);
    final selectActive = selectedCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.fullscreen),
          tooltip: 'Full screen blueprint',
          onPressed: onFullscreen,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.share, size: 18),
          tooltip: 'Export apartment',
          onPressed: onShare,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            allSelected ? Icons.deselect : Icons.select_all,
            color: onSelectAll == null
                ? disabledColor
                : (selectActive ? theme.colorScheme.primary : null),
          ),
          tooltip: allSelected
              ? 'Deselect all rooms'
              : 'Select all rooms on blueprint',
          onPressed: onSelectAll,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.undo, color: canUndo ? null : disabledColor),
          tooltip: 'Undo move',
          onPressed: canUndo ? onUndo : null,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.redo, color: canRedo ? null : disabledColor),
          tooltip: 'Redo move',
          onPressed: canRedo ? onRedo : null,
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
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.28);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.undo, color: canUndo ? null : disabledColor),
          tooltip: 'Undo move',
          onPressed: canUndo ? onUndo : null,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.redo, color: canRedo ? null : disabledColor),
          tooltip: 'Redo move',
          onPressed: canRedo ? onRedo : null,
        ),
      ],
    );
  }
}
