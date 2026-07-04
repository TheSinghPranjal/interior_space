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

class LibrarySectionScreen extends ConsumerStatefulWidget {
  const LibrarySectionScreen({
    super.key,
    required this.category,
    this.currentTexturePath,
    this.onSelect,
    this.pickerMode = false,
  });

  final MaterialCategory category;
  final String? currentTexturePath;
  final ValueChanged<MaterialItem>? onSelect;
  final bool pickerMode;

  @override
  ConsumerState<LibrarySectionScreen> createState() => _LibrarySectionScreenState();
}

class _LibrarySectionScreenState extends ConsumerState<LibrarySectionScreen> {
  String _selectedSub = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();
  MaterialItem? _selected;
  final Set<String> _favorites = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MaterialItem> _filtered() {
    final notifier = ref.read(materialLibraryProvider.notifier);
    var list = notifier.byCategory(widget.category);
    if (_selectedSub != 'all') {
      list = list.where((m) => m.subCategory == _selectedSub).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (m) =>
                m.name.toLowerCase().contains(q) ||
                m.subCategory.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = ref.watch(materialLibraryProvider);
    if (!library.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final subs = MaterialLibraryConstants.subsByCategory[widget.category]!;
    final items = _filtered();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(MaterialLibraryConstants.categoryTitle(widget.category)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add custom material',
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.only(bottom: 12),
            child: SubCategoryChips(
              categories: subs.keys.toList(),
              selected: _selectedSub,
              onSelected: (s) => setState(() => _selectedSub = s),
              labels: subs,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? _emptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return MaterialCard(
                        item: item,
                        isSelected: _selected?.id == item.id ||
                            widget.currentTexturePath == item.filePath ||
                            widget.currentTexturePath == item.assetPath,
                        isFavorited: _favorites.contains(item.id),
                        onTap: () => _selectItem(item),
                        onFavorite: () {
                          setState(() {
                            if (_favorites.contains(item.id)) {
                              _favorites.remove(item.id);
                            } else {
                              _favorites.add(item.id);
                            }
                          });
                        },
                        onDelete: item.isUserAdded
                            ? () => _confirmDelete(item)
                            : null,
                      );
                    },
                  ),
          ),
          if (widget.pickerMode && _selected != null) _applyBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Texture'),
      ),
    );
  }

  Future<void> _selectItem(MaterialItem item) async {
    setState(() => _selected = item);
    widget.onSelect?.call(item);
    if (widget.pickerMode) {
      final path = await ref.read(textureServiceProvider).materialToTexturePath(item);
      if (!mounted) return;
      Navigator.pop(context, path);
    }
  }

  Widget _applyBar() {
    final selected = _selected!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: MaterialCard(item: selected, showLabel: false),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  MaterialLibraryConstants.subLabel(selected.subCategory),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () async {
              final path =
                  await ref.read(textureServiceProvider).materialToTexturePath(selected);
              if (!mounted) return;
              Navigator.pop(context, path);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.texture, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No materials found', style: TextStyle(color: Colors.grey.shade400)),
          TextButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add your own'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<MaterialItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMaterialSheet(
        defaultCategory: widget.category,
        defaultSubCategory: _selectedSub == 'all' ? null : _selectedSub,
      ),
    );
    if (mounted) setState(() {});
  }

  void _confirmDelete(MaterialItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Remove "${item.name}" from your library?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(materialLibraryProvider.notifier).deleteUserMaterial(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
