import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/texture_service.dart';

/// Upload / change / remove texture with a thumbnail preview of the selected image.
class TextureUploadField extends ConsumerWidget {
  const TextureUploadField({
    super.key,
    required this.texturePath,
    required this.onPick,
    this.onClear,
    this.enabled = true,
    this.uploadLabel = 'Upload Texture',
    this.changeLabel = 'Change Texture',
  });

  final String? texturePath;
  final Future<void> Function() onPick;
  final VoidCallback? onClear;
  final bool enabled;
  final String uploadLabel;
  final String changeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (texturePath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _TexturePreview(path: texturePath!),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: enabled ? () => onPick() : null,
                icon: const Icon(Icons.upload_file),
                label: Text(texturePath == null ? uploadLabel : changeLabel),
              ),
            ),
            if (texturePath != null && onClear != null && enabled) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove texture',
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TexturePreview extends ConsumerStatefulWidget {
  const _TexturePreview({required this.path});

  final String path;

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
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (!kIsWeb && !widget.path.startsWith('memory://')) {
      return Image.file(
        File(widget.path),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 40),
    );
  }
}
