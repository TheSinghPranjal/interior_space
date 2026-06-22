import 'package:flutter/material.dart';

/// Shows a confirmation dialog before destructive delete actions.
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Mini building icon with per-apartment accent color (reference tab design).
class ApartmentBuildingIcon extends StatelessWidget {
  const ApartmentBuildingIcon({
    super.key,
    required this.color,
    this.size = 40,
  });

  final Color color;
  final double size;

  static Color colorForIndex(int index) {
    const palette = [
      Color(0xFFE8874A),
      Color(0xFF5B9BD5),
      Color(0xFF6BBF59),
      Color(0xFF9B7FD4),
      Color(0xFFE05A7A),
      Color(0xFF4DB6AC),
      Color(0xFFFFB74D),
      Color(0xFF7986CB),
      Color(0xFFA1887F),
      Color(0xFF4FC3F7),
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tree = size * 0.16;
    final buildingW = size * 0.38;
    final buildingH = size * 0.52;

    return SizedBox(
      width: size,
      height: size * 0.72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * 0.04,
            bottom: 0,
            child: _MiniTree(size: tree),
          ),
          Positioned(
            right: size * 0.04,
            bottom: 0,
            child: _MiniTree(size: tree),
          ),
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: buildingW,
              height: buildingH,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(2, (_) {
                      return Container(
                        width: buildingW * 0.18,
                        height: buildingH * 0.12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTree extends StatelessWidget {
  const _MiniTree({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF66BB6A),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: size * 0.18,
          height: size * 0.35,
          color: const Color(0xFF8D6E63),
        ),
      ],
    );
  }
}
