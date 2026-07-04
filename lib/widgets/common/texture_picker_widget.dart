import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/material_item.dart';
import '../../providers/material_library_provider.dart';
import '../../screens/material_library/material_library_screen.dart';
import '../../services/texture_service.dart';
import '../../widgets/material_library/add_material_sheet.dart';

/// Browse the material library or upload a custom texture.
/// No category boundary — any material can be applied anywhere.
class TexturePickerWidget extends ConsumerWidget {
  const TexturePickerWidget({
    super.key,
    required this.texturePath,
    required this.onTextureSelected,
    this.onClear,
    this.enabled = true,
    this.uploadLabel = 'Upload Texture',
    this.changeLabel = 'Change Texture',
    this.previewHeight = 120,
  });

  final String? texturePath;
  final ValueChanged<String> onTextureSelected;
  final VoidCallback? onClear;
  final bool enabled;
  final String uploadLabel;
  final String changeLabel;
  final double previewHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasTexture = texturePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTexture) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _TexturePreview(path: texturePath!, height: previewHeight),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: enabled ? () => _browseLibrary(context, ref) : null,
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text(hasTexture ? changeLabel : 'Browse Library'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? () => _showUploadOptions(context, ref) : null,
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(hasTexture ? 'Upload' : uploadLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: enabled
                ? () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MaterialLibraryScreen(),
                      ),
                    )
                : null,
            icon: const Icon(Icons.collections_outlined, size: 18),
            label: const Text('Open Material Library'),
          ),
        ),
        if (hasTexture && onClear != null && enabled) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onClear,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 18),
              label: Text('Remove texture', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _browseLibrary(BuildContext context, WidgetRef ref) async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialLibraryScreen(
          currentTexturePath: texturePath,
          pickerMode: true,
        ),
      ),
    );
    if (path != null) onTextureSelected(path);
  }

  Future<void> _showUploadOptions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD8E8E2),
                child: Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              ),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD8E8E2),
                child: Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD8E8E2),
                child: Icon(Icons.add_circle_outline, color: AppTheme.primary),
              ),
              title: const Text('Add to Material Library'),
              subtitle: const Text('Save for reuse across the app'),
              onTap: () {
                Navigator.pop(context);
                _addToLibrary(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final textureService = ref.read(textureServiceProvider);
    final path = source == ImageSource.camera
        ? await textureService.pickAndSaveTextureFromCamera()
        : await textureService.pickAndSaveTexture();
    if (path == null || !context.mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to Library?'),
        content: const Text(
          'Save this texture to your Material Library so it stays available after you close the app?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Just use it')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save to Library'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      final name = path.split('/').last.split('_').skip(1).join('_');
      await ref.read(materialLibraryProvider.notifier).addUserMaterial(
            MaterialItem(
              id: 'user_${DateTime.now().millisecondsSinceEpoch}',
              name: name.isEmpty ? 'Custom texture' : name,
              category: MaterialCategory.floor,
              subCategory: 'custom',
              filePath: path,
              isUserAdded: true,
              createdAt: DateTime.now(),
            ),
          );
    }

    onTextureSelected(path);
  }

  Future<void> _addToLibrary(BuildContext context, WidgetRef ref) async {
    final item = await showModalBottomSheet<MaterialItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMaterialSheet(),
    );
    if (item == null || !context.mounted) return;
    final path = await ref.read(textureServiceProvider).materialToTexturePath(item);
    onTextureSelected(path);
  }
}

class _TexturePreview extends ConsumerStatefulWidget {
  const _TexturePreview({required this.path, required this.height});

  final String path;
  final double height;

  @override
  ConsumerState<_TexturePreview> createState() => _TexturePreviewState();
}

class _TexturePreviewState extends ConsumerState<_TexturePreview> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TexturePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    if (widget.path.startsWith('memory://')) {
      final dataUrl =
          await ref.read(textureServiceProvider).resolveTextureDataUrl(widget.path);
      if (!mounted) return;
      if (dataUrl != null && dataUrl.contains(',')) {
        setState(() => _bytes = base64Decode(dataUrl.split(',').last));
      } else {
        setState(() => _bytes = null);
      }
      return;
    }

    if (!kIsWeb) {
      final file = File(widget.path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) setState(() => _bytes = bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    if (!kIsWeb && !widget.path.startsWith('memory://')) {
      return Image.file(
        File(widget.path),
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 38,
      ),
    );
  }
}
