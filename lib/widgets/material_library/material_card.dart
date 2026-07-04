import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/material_library_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/material_item.dart';

class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.onFavorite,
    this.isFavorited = false,
    this.showLabel = true,
  });

  final MaterialItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final bool isFavorited;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.primary, width: 2.5)
                        : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildPreview(),
                  ),
                ),
                if (onFavorite != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isFavorited ? Colors.red.shade400 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                if (item.isUserAdded)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Mine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (item.isUserAdded && onDelete != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              item.name,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              MaterialLibraryConstants.subLabel(item.subCategory),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (item.filePath != null) {
      if (item.filePath!.startsWith('memory://')) {
        return _colorPreview();
      }
      return Image.file(
        File(item.filePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _colorPreview(),
      );
    }
    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _colorPreview(),
      );
    }
    return _colorPreview();
  }

  Widget _colorPreview() {
    var color = Colors.grey.shade300;
    if (item.colorHex != null) {
      try {
        final hex = item.colorHex!.replaceAll('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return Container(
      color: color,
      child: item.colorHex == null
          ? const Center(child: Icon(Icons.texture, color: Colors.white54, size: 32))
          : null,
    );
  }
}
