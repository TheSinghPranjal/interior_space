import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/material_library_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/material_item.dart';
import '../../providers/material_library_provider.dart';
import '../../services/texture_service.dart';
import '../../widgets/material_library/add_material_sheet.dart';
import '../../widgets/material_library/material_card.dart';
import '../../widgets/material_library/sub_category_chips.dart';
import 'library_section_screen.dart';

class MaterialLibraryScreen extends ConsumerStatefulWidget {
  const MaterialLibraryScreen({
    super.key,
    this.onMaterialSelected,
    this.currentTexturePath,
    this.pickerMode = false,
  });

  final ValueChanged<MaterialItem>? onMaterialSelected;
  final String? currentTexturePath;
  final bool pickerMode;

  @override
  ConsumerState<MaterialLibraryScreen> createState() => _MaterialLibraryScreenState();
}

class _MaterialLibraryScreenState extends ConsumerState<MaterialLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _searching = false;

  static const _hubs = [
    _HubCard(
      cat: MaterialCategory.floor,
      icon: Icons.grid_on,
      label: 'Floor Library',
      sub: 'Tiles, wood,\nmarble & more',
      color: Color(0xFFE8F0EB),
    ),
    _HubCard(
      cat: MaterialCategory.ceiling,
      icon: Icons.wb_shade_outlined,
      label: 'Ceiling Library',
      sub: 'Gypsum, wood,\nPOP & more',
      color: Color(0xFFF0EDE8),
    ),
    _HubCard(
      cat: MaterialCategory.wall,
      icon: Icons.view_agenda_outlined,
      label: 'Wall Library',
      sub: 'Paints, wallpapers,\npanels & more',
      color: Color(0xFFE8EDF0),
    ),
    _HubCard(
      cat: MaterialCategory.furniture,
      icon: Icons.chair_outlined,
      label: 'Furniture Library',
      sub: 'Sofas, tables,\nchairs & more',
      color: Color(0xFFF0ECE8),
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = ref.watch(materialLibraryProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Search all materials...',
                  border: InputBorder.none,
                ),
              )
            : null,
        flexibleSpace: _searching
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 8, 56, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Material Library', style: theme.textTheme.titleLarge),
                      Text(
                        'Explore materials and textures for your space',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _search = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add custom material',
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: !library.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : _searching && _search.isNotEmpty
              ? _buildSearchResults(library)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHubGrid()),
                    ..._buildSectionSliver(library, MaterialCategory.floor),
                    ..._buildSectionSliver(library, MaterialCategory.ceiling),
                    ..._buildSectionSliver(library, MaterialCategory.wall),
                    ..._buildSectionSliver(library, MaterialCategory.furniture),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Texture'),
      ),
    );
  }

  Widget _buildHubGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: _hubs.length,
        itemBuilder: (_, i) => _HubTile(
          hub: _hubs[i],
          onTap: () => _openSection(_hubs[i].cat),
        ),
      ),
    );
  }

  List<Widget> _buildSectionSliver(MaterialLibraryState library, MaterialCategory cat) {
    final notifier = ref.read(materialLibraryProvider.notifier);
    final items = notifier.byCategory(cat).take(10).toList();
    if (items.isEmpty) return [];
    final title = MaterialLibraryConstants.categoryTitle(cat);
    final subs = MaterialLibraryConstants.subsByCategory[cat]!;

    return [
      SliverToBoxAdapter(
        child: _SectionHeader(title: title, onViewAll: () => _openSection(cat)),
      ),
      SliverToBoxAdapter(
        child: SubCategoryChips(
          categories: subs.keys.toList(),
          selected: 'all',
          onSelected: (_) => _openSection(cat),
          labels: subs,
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 120,
              child: MaterialCard(
                item: items[i],
                isSelected: _isSelected(items[i]),
              onTap: () {
                if (widget.pickerMode) {
                  _selectMaterial(items[i]);
                } else {
                  _openSection(cat);
                }
              },
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSearchResults(MaterialLibraryState library) {
    final results = ref.read(materialLibraryProvider.notifier).search(_search);
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_search"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => MaterialCard(
        item: results[i],
        isSelected: _isSelected(results[i]),
        onTap: () => _selectMaterial(results[i]),
      ),
    );
  }

  bool _isSelected(MaterialItem item) {
    if (widget.currentTexturePath == null) return false;
    return item.filePath == widget.currentTexturePath ||
        item.assetPath == widget.currentTexturePath;
  }

  Future<void> _selectMaterial(MaterialItem item) async {
    widget.onMaterialSelected?.call(item);
    if (widget.pickerMode) {
      final path = await ref.read(textureServiceProvider).materialToTexturePath(item);
      if (!mounted) return;
      Navigator.pop(context, path);
    }
  }

  void _openSection(MaterialCategory cat) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => LibrarySectionScreen(
          category: cat,
          currentTexturePath: widget.currentTexturePath,
          onSelect: widget.onMaterialSelected,
          pickerMode: widget.pickerMode,
        ),
      ),
    );
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<MaterialItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMaterialSheet(),
    );
    if (mounted) setState(() {});
  }
}

class _HubCard {
  const _HubCard({
    required this.cat,
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  final MaterialCategory cat;
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.hub, required this.onTap});

  final _HubCard hub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: hub.color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Center(
                  child: Icon(hub.icon, size: 36, color: AppTheme.primary),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hub.label,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hub.sub,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
