import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/premium_catalog_item.dart';

/// Slide-in premium catalog grid for the furniture placement screen.
class PremiumCatalogPanel extends StatelessWidget {
  const PremiumCatalogPanel({
    super.key,
    required this.onClose,
    required this.onAdd,
    this.embedded = false,
  });

  final VoidCallback onClose;
  final ValueChanged<PremiumCatalogDefinition> onAdd;
  /// When true, omits the panel toolbar — parent screen keeps the header.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Premium Catalog',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap Add to place in your room',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Premium Catalog',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap Add to place items',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.72,
              ),
              itemCount: premiumFurnitureCatalog.length,
              itemBuilder: (context, index) {
                final item = premiumFurnitureCatalog[index];
                return _PremiumCatalogCard(
                  definition: item,
                  onAdd: () => onAdd(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCatalogCard extends StatelessWidget {
  const _PremiumCatalogCard({
    required this.definition,
    required this.onAdd,
  });

  final PremiumCatalogDefinition definition;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: _CatalogPreviewArt(definition: definition),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  definition.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylized preview art suggesting a 3D render for each catalog item.
class _CatalogPreviewArt extends StatelessWidget {
  const _CatalogPreviewArt({required this.definition});

  final PremiumCatalogDefinition definition;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CatalogPreviewPainter(definition: definition),
      child: const SizedBox.expand(),
    );
  }
}

class _CatalogPreviewPainter extends CustomPainter {
  _CatalogPreviewPainter({required this.definition});

  final PremiumCatalogDefinition definition;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          definition.previewTop.withValues(alpha: 0.55),
          definition.previewBottom.withValues(alpha: 0.85),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    switch (definition.id) {
      case PremiumCatalogId.bathtubWithWater:
        _drawBathtub(canvas, size, withWater: true, vintage: false);
      case PremiumCatalogId.bathtubVintage:
        _drawBathtub(canvas, size, withWater: false, vintage: true);
      case PremiumCatalogId.pottedPlant:
        _drawPlant(canvas, size, style: _PlantStyle.potted);
      case PremiumCatalogId.indoorPlant:
        _drawPlant(canvas, size, style: _PlantStyle.indoor);
      case PremiumCatalogId.monstera:
        _drawPlant(canvas, size, style: _PlantStyle.monstera);
      case PremiumCatalogId.luxuryBed:
        _drawBed(canvas, size);
      case PremiumCatalogId.sedanCar:
        _drawCar(canvas, size);
    }
  }

  void _drawCar(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.58;
    final carW = size.width * 0.72;
    final carH = size.height * 0.22;

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: carW, height: carH),
      Radius.circular(carH * 0.28),
    );
    canvas.drawRRect(body, Paint()..color = definition.previewTop);

    final cabin = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - carH * 0.18),
        width: carW * 0.52,
        height: carH * 0.55,
      ),
      Radius.circular(carH * 0.2),
    );
    canvas.drawRRect(cabin, Paint()..color = definition.previewTop.withValues(alpha: 0.85));

    final glassPaint = Paint()..color = definition.previewAccent.withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - carH * 0.22),
          width: carW * 0.34,
          height: carH * 0.28,
        ),
        const Radius.circular(4),
      ),
      glassPaint,
    );

    for (final dx in [-carW * 0.34, carW * 0.34]) {
      canvas.drawCircle(
        Offset(cx + dx, cy + carH * 0.42),
        carH * 0.18,
        Paint()..color = definition.previewBottom,
      );
      canvas.drawCircle(
        Offset(cx + dx, cy + carH * 0.42),
        carH * 0.1,
        Paint()..color = definition.previewAccent,
      );
    }

    canvas.drawRRect(
      body,
      Paint()
        ..color = definition.previewAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawBathtub(Canvas canvas, Size size, {required bool withWater, required bool vintage}) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.58;
    final tubW = size.width * 0.62;
    final tubH = size.height * 0.28;

    if (vintage) {
      for (final dx in [-tubW * 0.38, tubW * 0.38]) {
        canvas.drawCircle(
          Offset(cx + dx, cy + tubH * 0.55),
          tubH * 0.18,
          Paint()..color = definition.previewAccent,
        );
      }
    }

    final tubRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: tubW, height: tubH),
      Radius.circular(vintage ? tubH * 0.45 : tubH * 0.22),
    );
    canvas.drawRRect(
      tubRect,
      Paint()..color = definition.previewBottom,
    );

    if (withWater) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - tubH * 0.05),
            width: tubW * 0.82,
            height: tubH * 0.55,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = definition.previewTop.withValues(alpha: 0.85),
      );
    }

    canvas.drawRRect(
      tubRect,
      Paint()
        ..color = definition.previewAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPlant(Canvas canvas, Size size, {required _PlantStyle style}) {
    final cx = size.width * 0.5;
    final potTop = size.height * 0.72;
    final potW = size.width * (style == _PlantStyle.monstera ? 0.34 : 0.28);
    final potH = size.height * 0.18;

    final pot = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - potW / 2, potTop, potW, potH),
      const Radius.circular(6),
    );
    canvas.drawRRect(pot, Paint()..color = definition.previewBottom);

    final leafPaint = Paint()..color = definition.previewTop;
    final accentPaint = Paint()..color = definition.previewAccent;

    if (style == _PlantStyle.monstera) {
      for (var i = 0; i < 5; i++) {
        final angle = -0.8 + i * 0.4;
        _drawLeaf(canvas, Offset(cx, potTop - 8), 34, 18, angle, leafPaint, split: true);
      }
    } else if (style == _PlantStyle.indoor) {
      for (var i = 0; i < 8; i++) {
        final angle = -1.2 + i * 0.35;
        _drawLeaf(canvas, Offset(cx, potTop - 4), 22, 10, angle, leafPaint);
      }
    } else {
      canvas.drawCircle(Offset(cx, potTop - 22), 26, leafPaint);
      canvas.drawCircle(Offset(cx - 14, potTop - 30), 8, accentPaint);
      canvas.drawCircle(Offset(cx + 10, potTop - 28), 8, accentPaint);
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    double angle,
    Paint paint, {
    bool split = false,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(w * 0.5, -h * 0.4, w, -h)
      ..quadraticBezierTo(w * 0.5, -h * 0.75, 0, -h * 0.95)
      ..close();
    canvas.drawPath(path, paint);
    if (split) {
      canvas.drawLine(
        Offset(w * 0.15, -h * 0.15),
        Offset(w * 0.75, -h * 0.85),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
  }

  void _drawBed(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.48,
      size.width * 0.72,
      size.height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = definition.previewBottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 8, rect.top + 8, rect.width - 16, rect.height * 0.42),
        const Radius.circular(6),
      ),
      Paint()..color = definition.previewAccent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 12, rect.top + rect.height * 0.52, rect.width - 24, rect.height * 0.34),
        const Radius.circular(6),
      ),
      Paint()..color = definition.previewTop,
    );
  }

  @override
  bool shouldRepaint(covariant _CatalogPreviewPainter oldDelegate) =>
      oldDelegate.definition.id != definition.id;
}

enum _PlantStyle { potted, indoor, monstera }
