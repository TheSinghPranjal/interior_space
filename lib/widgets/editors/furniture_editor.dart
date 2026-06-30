import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/enums.dart';
import '../../models/furniture_item.dart';
import '../../models/premium_catalog_item.dart';
import '../../models/room_design.dart';
import '../../providers/placed_item_clipboard_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../services/texture_service.dart';
import '../common/placed_item_config_menu.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/dimension_slider.dart';
import '../common/item_editor_header.dart';
import '../common/section_card.dart';
import '../common/texture_upload_field.dart';
import 'premium_catalog_panel.dart';
import 'wall_tv_unit_card.dart';

class FurnitureEditor extends ConsumerStatefulWidget {
  const FurnitureEditor({super.key});

  @override
  ConsumerState<FurnitureEditor> createState() => _FurnitureEditorState();
}

class _FurnitureEditorState extends ConsumerState<FurnitureEditor> {
  bool _catalogOpen = false;

  void _openCatalog() {
    if (!ref.read(premiumFurnitureProvider)) return;
    setState(() => _catalogOpen = true);
  }

  void _closeCatalog() => setState(() => _catalogOpen = false);

  void _addCatalogItem(PremiumCatalogDefinition definition) {
    ref.read(roomDesignProvider.notifier).addPremiumCatalogItem(definition.id);
    _closeCatalog();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${definition.name} added to placement')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final furniture = design.furniture;
    final wallTvUnits = design.wallTvUnits;
    final premiumEnabled = ref.watch(premiumFurnitureProvider);
    final notifier = ref.read(roomDesignProvider.notifier);
    final standardFurniture =
        furniture.where((f) => !f.isPremiumCatalogItem).toList();
    final premiumFurniture =
        furniture.where((f) => f.isPremiumCatalogItem).toList();
    final catalogHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.passthrough,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _catalogOpen
          ? ListView(
              key: const ValueKey('catalog_view'),
              children: [
                SectionCard(
                  title: 'Furniture Placement',
                  subtitle:
                      'Premium catalog • Tap Add on any item to place in your room',
                  trailing: TextButton.icon(
                    onPressed: _closeCatalog,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                  child: const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.45),
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: SizedBox(
                        height: catalogHeight,
                        child: PremiumCatalogPanel(
                          embedded: true,
                          onClose: _closeCatalog,
                          onAdd: _addCatalogItem,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            )
          : ListView(
              key: const ValueKey('placement_view'),
              children: [
                SectionCard(
                  title: 'Furniture Placement',
                  subtitle:
                      'Add items to the blueprint • Wardrobe & Wall TV included • Drag in Blueprint',
                  trailing: Tooltip(
                    message: premiumEnabled
                        ? 'Browse premium catalog'
                        : 'Enable Premium furniture in Settings to unlock',
                    child: TextButton.icon(
                      onPressed: premiumEnabled ? _openCatalog : null,
                      icon: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: premiumEnabled ? Colors.amber.shade800 : Colors.grey,
                      ),
                      label: const Text('Add More'),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...FurnitureType.values.map((type) {
                        return ActionChip(
                          avatar: Icon(type.icon, size: 16),
                          label: Text(type.label),
                          onPressed: () => notifier.addFurniture(type),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.tv, size: 16),
                        label: const Text('Wall TV Unit'),
                        onPressed: notifier.addWallTvUnit,
                      ),
                    ],
                  ),
                ),
                if (standardFurniture.isNotEmpty || wallTvUnits.isNotEmpty)
                  SectionCard(
                    title: 'Placed Items',
                    child: Column(
                      children: [
                        ...standardFurniture.map(
                          (item) => _FurnitureCard(
                            item: item,
                            design: design,
                          ),
                        ),
                        ...wallTvUnits.map(
                          (unit) => WallTvUnitCard(
                            unit: unit,
                            units: wallTvUnits,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (premiumFurniture.isNotEmpty)
                  SectionCard(
                    title: 'Premium Catalog Items',
                    subtitle: 'Added from Premium Catalog • Drag in Blueprint',
                    titleBadge:
                        Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade700),
                    child: Column(
                      children: premiumFurniture
                          .map(
                            (item) => _FurnitureCard(
                              item: item,
                              design: design,
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FurnitureCard extends ConsumerStatefulWidget {
  const _FurnitureCard({
    required this.item,
    required this.design,
  });

  final FurnitureItem item;
  final RoomDesign design;

  @override
  ConsumerState<_FurnitureCard> createState() => _FurnitureCardState();
}

class _FurnitureCardState extends ConsumerState<_FurnitureCard>
    with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 340);

  bool _expanded = false;
  bool _editingEnabled = false;
  late final AnimationController _expandController = AnimationController(
    vsync: this,
    duration: _expandDuration,
  );
  late final Animation<double> _expandAnimation = CurvedAnimation(
    parent: _expandController,
    curve: Curves.easeInOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );

  FurnitureItem get item => widget.item;
  RoomDesign get design => widget.design;

  IconData get _itemIcon {
    final catalog = premiumCatalogByIdKey(item.premiumCatalogId);
    return catalog?.icon ?? item.type.icon;
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(roomDesignProvider.notifier);
    final enabled = _editingEnabled;
    final clipboard = ref.watch(placedItemClipboardProvider);
    final canPaste = clipboard.canPasteTo(item.type);

    return EditorItemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemEditorHeader(
            title: FurnitureItem.displayLabel(design.furniture, item),
            icon: _itemIcon,
            configMenu: PlacedItemConfigMenu(
              showPaste: canPaste && !item.isPremiumCatalogItem,
              pasteLabel: canPaste ? 'Paste ${item.type.label} configuration' : null,
              onCopy: () {
                ref.read(placedItemClipboardProvider.notifier).copyFurniture(item);
                showPlacedItemConfigSnackBar(
                  context,
                  '${FurnitureItem.displayLabel(design.furniture, item)} configuration copied',
                );
              },
              onPaste: () {
                final snapshot = ref.read(placedItemClipboardProvider).furniture;
                if (snapshot == null || snapshot.type != item.type) return;
                final ok = notifier.pasteFurnitureConfig(item.id, snapshot);
                if (ok && context.mounted) {
                  showPlacedItemConfigSnackBar(
                    context,
                    '${FurnitureItem.displayLabel(design.furniture, item)} configuration pasted',
                  );
                }
              },
            ),
            expanded: _expanded,
            onToggleExpand: _toggleExpand,
            expandAnimationDuration: _expandDuration,
            editingEnabled: _editingEnabled,
            onToggleEdit: () => setState(() => _editingEnabled = !_editingEnabled),
            onDelete: () => notifier.removeFurniture(item.id),
          ),
          if (item.isPremiumCatalogItem)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Premium catalog',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade800,
                        ),
                  ),
                ],
              ),
            ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _buildExpandedContent(notifier, enabled),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(RoomDesignNotifier notifier, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!enabled)
          const EditorHelperText(
            'Tap edit to change parameters, or drag in Blueprint view',
          ),
        if (item.isWallMounted) ...[
              DropdownButtonFormField<WallId>(
                value: item.wall ?? WallId.left,
                decoration: const InputDecoration(labelText: 'Wall'),
                items: WallId.values
                    .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                    .toList(),
                onChanged: enabled
                    ? (w) {
                        if (w != null) notifier.updateFurniture(item.copyWith(wall: w));
                      }
                    : null,
              ),
              DimensionSlider(
                label: 'Position from wall edge',
                value: item.positionFromEdge,
                min: 0,
                max: 12,
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(positionFromEdge: v))
                    : null,
              ),
            ] else ...[
              DimensionSlider(
                label: 'Distance from left wall',
                value: item.positionFromLeftFt(design.dimensions),
                min: 0,
                max: item.maxPositionFromLeftFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(
                          item.copyWith(
                            blueprintX: item.blueprintXFromLeftFt(v, design.dimensions),
                          ),
                        )
                    : null,
              ),
              DimensionSlider(
                label: 'Distance from front wall',
                value: item.positionFromFrontFt(design.dimensions),
                min: 0,
                max: item.maxPositionFromFrontFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(
                          item.copyWith(
                            blueprintY: item.blueprintYFromFrontFt(v, design.dimensions),
                          ),
                        )
                    : null,
              ),
              DimensionSlider(
                label: 'Rotation',
                value: item.rotation,
                min: 0,
                max: 360,
                suffix: '°',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(rotation: v))
                    : null,
              ),
            ],
            DimensionSlider(
              label: 'Width',
              value: item.width,
              min: 1,
              max: 12,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(width: v)) : null,
            ),
            DimensionSlider(
              label: 'Height',
              value: item.height,
              min: 1,
              max: 9,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(height: v)) : null,
            ),
            DimensionSlider(
              label: 'Depth',
              value: item.depth,
              min: 1,
              max: 8,
              suffix: 'ft',
              onChanged: enabled ? (v) => notifier.updateFurniture(item.copyWith(depth: v)) : null,
            ),
            if (item.supportsHeightFromFloor)
              DimensionSlider(
                label: 'Height from floor',
                value: item.heightFromFloor,
                min: 0,
                max: item.maxHeightFromFloorFt(design.dimensions),
                suffix: 'ft',
                onChanged: enabled
                    ? (v) => notifier.updateFurniture(item.copyWith(heightFromFloor: v))
                    : null,
              ),
            ..._typeSpecificFields(item, enabled, notifier),
            ColorPickerField(
              label: 'Color',
              colorHex: item.color,
              enabled: enabled,
              onChanged: (c) => notifier.updateFurniture(item.copyWith(color: c)),
            ),
            if (item.supportsTextureUpload && enabled)
              TextureUploadField(
                texturePath: item.texturePath,
                onPick: () async {
                  final path = await ref.read(textureServiceProvider).pickAndSaveTexture();
                  if (path != null) {
                    notifier.updateFurniture(item.copyWith(texturePath: path));
                  }
                },
                onClear: item.texturePath == null
                    ? null
                    : () => notifier.updateFurniture(
                          item.copyWith(clearTexture: true),
                        ),
              ),
      ],
    );
  }

  List<Widget> _typeSpecificFields(
    FurnitureItem item,
    bool enabled,
    RoomDesignNotifier notifier,
  ) {
    if (item.isPremiumCatalogItem) return const [];
    return switch (item.type) {
      FurnitureType.diningTable => [
          DropdownButtonFormField<DiningTableShape>(
            value: item.diningTableShape,
            decoration: const InputDecoration(labelText: 'Table Shape'),
            items: DiningTableShape.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
          DropdownButtonFormField<FurnitureMaterialPreset>(
            value: item.material,
            decoration: const InputDecoration(labelText: 'Material'),
            items: <FurnitureMaterialPreset>[
              FurnitureMaterialPreset.wood,
              FurnitureMaterialPreset.whiteMatte,
              FurnitureMaterialPreset.glossy,
              FurnitureMaterialPreset.metallic,
            ].map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) {
                      notifier.updateFurniture(item.copyWith(materialPreset: m.name));
                    }
                  }
                : null,
          ),
        ],
      FurnitureType.storageUnit => [
          DropdownButtonFormField<StorageUnitStyle>(
            value: item.storageUnitStyle,
            decoration: const InputDecoration(labelText: 'Cabinet Style'),
            items: StorageUnitStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
          DropdownButtonFormField<FurnitureMaterialPreset>(
            value: item.material,
            decoration: const InputDecoration(labelText: 'Material'),
            items: <FurnitureMaterialPreset>[
              FurnitureMaterialPreset.wood,
              FurnitureMaterialPreset.whiteMatte,
              FurnitureMaterialPreset.glossy,
              FurnitureMaterialPreset.metallic,
            ].map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) {
                      notifier.updateFurniture(item.copyWith(materialPreset: m.name));
                    }
                  }
                : null,
          ),
        ],
      FurnitureType.kitchenChimney => [
          DropdownButtonFormField<KitchenChimneyStyle>(
            value: item.chimneyStyle,
            decoration: const InputDecoration(labelText: 'Chimney Style'),
            items: KitchenChimneyStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: enabled
                ? (s) {
                    if (s != null) {
                      notifier.updateFurniture(item.copyWith(variant: s.name));
                    }
                  }
                : null,
          ),
        SizedBox(height: 10),
          DropdownButtonFormField<FurnitureMaterialPreset>(
            value: item.material,
            decoration: const InputDecoration(labelText: 'Finish'),
            items: <FurnitureMaterialPreset>[
              FurnitureMaterialPreset.stainlessSteel,
              FurnitureMaterialPreset.black,
              FurnitureMaterialPreset.white,
              FurnitureMaterialPreset.glossy,
            ].map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
            onChanged: enabled
                ? (m) {
                    if (m != null) {
                      notifier.updateFurniture(item.copyWith(materialPreset: m.name));
                    }
                  }
                : null,
          ),
        ],
      _ => const <Widget>[],
    };
  }
}
