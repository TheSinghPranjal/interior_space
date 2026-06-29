import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Displays a company logo or cover image from a stored path.
class CompanyImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(
        placeholderIcon,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );

    if (path == null || path!.isEmpty) {
      return _clip(placeholder);
    }

    if (path!.startsWith('memory://')) {
      return FutureBuilder<ImageProvider?>(
        future: _memoryImageProvider(path!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return _clip(placeholder);
          }
          return _clip(
            Image(
              image: snapshot.data!,
              width: width,
              height: height,
              fit: fit,
            ),
          );
        },
      );
    }

    if (kIsWeb) {
      return _clip(placeholder);
    }

    final file = File(path!);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return _clip(placeholder);
        }
        return _clip(
          Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
          ),
        );
      },
    );
  }

  Widget _clip(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  static Future<ImageProvider?> _memoryImageProvider(String path) async {
    final id = path.replaceFirst('memory://', '');
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(id);
    if (data == null) return null;
    return MemoryImage(base64Decode(data));
  }
}
