import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/material_library_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/material_item.dart';
import '../../providers/material_library_provider.dart';
import '../../services/texture_service.dart';

class AddMaterialSheet extends ConsumerStatefulWidget {
  const AddMaterialSheet({
    super.key,
    this.defaultCategory,
    this.defaultSubCategory,
  });

  final MaterialCategory? defaultCategory;
  final String? defaultSubCategory;

  @override
  ConsumerState<AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends ConsumerState<AddMaterialSheet> {
  final _nameCtrl = TextEditingController();
  MaterialCategory _category = MaterialCategory.floor;
  String _subCategory = 'wood';
  File? _pickedFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.defaultCategory ?? MaterialCategory.floor;
    final subs = MaterialLibraryConstants.subCategoriesForAdd[_category]!;
    _subCategory = widget.defaultSubCategory != null &&
            subs.contains(widget.defaultSubCategory)
        ? widget.defaultSubCategory!
        : subs.first;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _pickedFile = File(picked.path));
    if (_nameCtrl.text.isEmpty) {
      final base = picked.path.split('/').last;
      final dot = base.lastIndexOf('.');
      final name = dot == -1 ? base : base.substring(0, dot);
      _nameCtrl.text = name.replaceAll('_', ' ');
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    setState(() => _loading = true);

    String? savedPath;
    if (_pickedFile != null) {
      savedPath = await ref.read(textureServiceProvider).saveUserMaterialFile(_pickedFile!);
    }

    final item = MaterialItem(
      id: 'user_${Random().nextInt(999999)}',
      name: _nameCtrl.text.trim(),
      category: _category,
      subCategory: _subCategory,
      filePath: savedPath,
      colorHex: _pickedFile == null ? '#CCCCCC' : null,
      isUserAdded: true,
      createdAt: DateTime.now(),
    );

    await ref.read(materialLibraryProvider.notifier).addUserMaterial(item);
    if (mounted) Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subs = MaterialLibraryConstants.subCategoriesForAdd[_category]!;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Add Material', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _showPickerOptions,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(_pickedFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload texture / image',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Material Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MaterialCategory.values.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(MaterialLibraryConstants.categoryShortLabel(cat)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _category = cat;
                      _subCategory =
                          MaterialLibraryConstants.subCategoriesForAdd[cat]!.first;
                    });
                  },
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Sub-category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: subs.map((sub) {
                final selected = _subCategory == sub;
                return ChoiceChip(
                  label: Text(MaterialLibraryConstants.subLabel(sub)),
                  selected: selected,
                  onSelected: (_) => setState(() => _subCategory = sub),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to Library'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}
