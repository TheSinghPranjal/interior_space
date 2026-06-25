import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/room_design_provider.dart';
import '../../services/export_service.dart';
import '../data/sketch_composite_exporter.dart';
import '../data/sketch_image_storage.dart';
import '../providers/sketch_controller.dart';
import 'sketch_canvas.dart';
import 'sketch_toolbar.dart';

class SketchView extends ConsumerWidget {
  const SketchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApartment = ref.watch(appSpaceModeProvider) == AppSpaceMode.apartment;

    return Stack(
      fit: StackFit.expand,
      children: [
        SketchCanvas(isApartment: isApartment),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SketchToolbar(
                    onExport: () => _exportSketch(context, ref, isApartment),
                    onPickImage: () => _pickImage(ref),
                    onAddText: () => _addTextAtCenter(context, ref),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const SketchToolOptionsPanel(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await SketchImageStorage.savePickedFile(File(picked.path));
    ref.read(sketchControllerProvider.notifier).addImage(path);
  }

  Future<void> _addTextAtCenter(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Notes, pricing, facing…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text != null) {
      ref.read(sketchControllerProvider.notifier).addTextAt(const Offset(0.4, 0.4), text);
    }
  }

  Future<void> _exportSketch(
    BuildContext context,
    WidgetRef ref,
    bool isApartment,
  ) async {
    final doc = ref.read(sketchControllerProvider);
    final exportService = ExportService();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(const SnackBar(content: Text('Rendering sketch…')));

    try {
      final bytes = isApartment
          ? await SketchCompositeExporter.renderApartment(
              project: ref.read(projectProvider),
              apartmentIndex: ref.read(projectProvider).safeActiveApartmentIndex,
              sketch: doc,
            )
          : await SketchCompositeExporter.renderRoom(
              room: ref.read(roomDesignProvider),
              sketch: doc,
            );

      final name = isApartment
          ? ref.read(projectProvider).apartmentLayout.name
          : ref.read(roomDesignProvider).name;
      final path = await exportService.saveScreenshot(bytes, '${name}_sketch');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Sketch saved to Downloads' : 'Sketch exported'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}
