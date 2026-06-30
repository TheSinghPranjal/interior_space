import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/project_provider.dart';
import '../providers/room_design_provider.dart';
import '../widgets/apartment/apartment_canvas.dart';
import '../widgets/blueprint/blueprint_canvas.dart';

enum FullscreenBlueprintMode { room, apartment }

/// Immersive blueprint viewer with pinch-to-zoom and pan.
class FullscreenBlueprintScreen extends ConsumerWidget {
  const FullscreenBlueprintScreen({super.key, required this.mode});

  final FullscreenBlueprintMode mode;

  static Future<void> open(
    BuildContext context, {
    required FullscreenBlueprintMode mode,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenBlueprintScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = switch (mode) {
      FullscreenBlueprintMode.room => ref.watch(roomDesignProvider).name,
      FullscreenBlueprintMode.apartment =>
        ref.watch(projectProvider).apartmentLayout.name,
    };

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text('$title Blueprint'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit full screen',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Pinch to zoom',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Full screen blueprint'),
                  content: const Text(
                    'Pinch with two fingers to zoom in and out. '
                    'Drag with one finger to pan when zoomed in.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: switch (mode) {
          FullscreenBlueprintMode.room => const BlueprintCanvas(immersive: true),
          FullscreenBlueprintMode.apartment => const ApartmentCanvas(immersive: true),
        },
      ),
    );
  }
}
