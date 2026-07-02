import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../domain/sketch_tool.dart';
import '../providers/sketch_controller.dart';

class SketchToolbar extends ConsumerWidget {
  const SketchToolbar({
    super.key,
    required this.onExport,
    required this.onPickImage,
    required this.onAddText,
  });

  final VoidCallback onExport;
  final VoidCallback onPickImage;
  final VoidCallback onAddText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(sketchControllerProvider);
    final controller = ref.read(sketchControllerProvider.notifier);
    final tool = doc.toolSettings.activeTool;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolChip(
                icon: Icons.edit_outlined,
                label: compact ? null : 'Pen',
                selected: tool == SketchTool.pen,
                onTap: () => controller.setTool(SketchTool.pen),
              ),
              _ToolChip(
                icon: Icons.highlight_outlined,
                label: compact ? null : 'Highlight',
                selected: tool == SketchTool.highlighter,
                onTap: () => controller.setTool(SketchTool.highlighter),
              ),
              _ToolChip(
                icon: Icons.auto_fix_off_outlined,
                label: compact ? null : 'Eraser',
                selected: tool == SketchTool.eraser,
                onTap: () => controller.setTool(SketchTool.eraser),
              ),
              _ToolChip(
                icon: Icons.category_outlined,
                label: compact ? null : 'Shapes',
                selected: tool == SketchTool.shapes,
                onTap: () => controller.setTool(SketchTool.shapes),
              ),
              _ToolChip(
                icon: Icons.title_outlined,
                label: compact ? null : 'Text',
                selected: tool == SketchTool.text,
                onTap: onAddText,
              ),
              _ToolChip(
                icon: Icons.image_outlined,
                label: compact ? null : 'Image',
                selected: tool == SketchTool.image,
                onTap: onPickImage,
              ),
              _ToolChip(
                icon: Icons.crop_outlined,
                label: compact ? null : 'Crop',
                selected: tool == SketchTool.crop,
                onTap: () => controller.setTool(SketchTool.crop),
              ),
              _ToolChip(
                icon: Icons.rotate_right_outlined,
                label: compact ? null : 'Rotate',
                selected: tool == SketchTool.rotate,
                onTap: () => controller.setTool(SketchTool.rotate),
              ),
              _ToolChip(
                icon: Icons.pan_tool_alt_outlined,
                label: compact ? null : 'Select',
                selected: tool == SketchTool.select,
                onTap: () => controller.setTool(SketchTool.select),
              ),
              const VerticalDivider(width: 16),
              IconButton(
                tooltip: 'Undo',
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                tooltip: 'Reset sketch',
                onPressed: () => _confirmReset(context, controller),
                icon: Icon(Icons.restart_alt, color: theme.colorScheme.error),
              ),
              IconButton(
                tooltip: 'Export',
                onPressed: onExport,
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, SketchController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset sketch?'),
        content: const Text('All annotations will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.resetSketch();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!, style: TextStyle(fontSize: 12, color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SketchToolOptionsPanel extends ConsumerWidget {
  const SketchToolOptionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(sketchControllerProvider);
    final controller = ref.read(sketchControllerProvider.notifier);
    final settings = doc.toolSettings;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (settings.activeTool == SketchTool.pen ||
                settings.activeTool == SketchTool.highlighter) ...[
              Text('Brush size', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: SketchBrushSize.values.map((size) {
                  return ChoiceChip(
                    label: Text(size.label, style: const TextStyle(fontSize: 11)),
                    selected: settings.brushSize == size,
                    onSelected: (_) => controller.setBrushSize(size),
                  );
                }).toList(),
              ),
            ],
            if (settings.activeTool == SketchTool.eraser) ...[
              Text('Eraser size', style: Theme.of(context).textTheme.labelMedium),
              Slider(
                value: settings.eraserSize,
                min: 4,
                max: 48,
                onChanged: controller.setEraserSize,
              ),
            ],
            if (settings.activeTool == SketchTool.rotate) ...[
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: controller.rotateBlueprint90,
                    child: const Text('90°'),
                  ),
                  OutlinedButton(
                    onPressed: () => controller.rotateBlueprintBy(3.141592653589793),
                    child: const Text('180°'),
                  ),
                  OutlinedButton(
                    onPressed: controller.resetBlueprintTransform,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
            if (settings.activeTool == SketchTool.shapes) ...[
              Text('Shape', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: SketchShapeKind.values.map((kind) {
                  return ChoiceChip(
                    label: Text(kind.name, style: const TextStyle(fontSize: 11)),
                    selected: settings.shapeKind == kind,
                    onSelected: (_) => controller.setShapeKind(kind),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
