import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Displays a company logo or cover image from a stored path.
class CompanyImage extends StatefulWidget {
  const CompanyImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  State<CompanyImage> createState() => _CompanyImageState();
}

class _CompanyImageState extends State<CompanyImage> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CompanyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _load();
    }
  }

  Future<void> _load() async {
    final path = widget.path;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _bytes = null);
      return;
    }

    setState(() => _loading = true);
    final bytes = await CompanyImageLoader.loadBytes(path);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child;
    if (_bytes != null) {
      child = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(theme),
      );
    } else if (!_loading &&
        !kIsWeb &&
        widget.path != null &&
        widget.path!.isNotEmpty &&
        !widget.path!.startsWith('memory://')) {
      child = Image.file(
        File(widget.path!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(theme),
      );
    } else {
      child = _placeholder(theme);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: _loading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            )
          : Icon(
              widget.placeholderIcon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
    );
  }
}

/// Loads company profile image bytes from memory or disk storage.
class CompanyImageLoader {
  static Future<Uint8List?> loadBytes(String path) async {
    if (path.startsWith('memory://')) {
      final prefs = await SharedPreferences.getInstance();
      final key = path.replaceFirst('memory://', '');
      final data = prefs.getString(key);
      if (data == null || data.isEmpty) return null;
      try {
        return base64Decode(data);
      } catch (e) {
        debugPrint('Company image memory decode failed: $e');
        return null;
      }
    }

    if (kIsWeb) return null;

    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('Company image file not found: $path');
        return null;
      }
      return file.readAsBytes();
    } catch (e) {
      debugPrint('Company image file read failed: $e');
      return null;
    }
  }
}
