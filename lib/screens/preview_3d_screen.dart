import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../providers/project_provider.dart';
import '../providers/room_design_provider.dart';
import '../services/export_service.dart';
import '../services/project_storage_service.dart';
import '../widgets/three_d/room_3d_viewer.dart';

class Preview3DScreen extends ConsumerStatefulWidget {
  const Preview3DScreen({super.key});

  @override
  ConsumerState<Preview3DScreen> createState() => _Preview3DScreenState();
}

class _Preview3DScreenState extends ConsumerState<Preview3DScreen> {
  final _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(design.name, style: const TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (action) => _handleExport(action),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'screenshot', child: Text('Save Screenshot')),
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              PopupMenuItem(value: 'project', child: Text('Share Project')),
              PopupMenuItem(value: 'save', child: Text('Save Project')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: const Room3DViewer(showControls: true),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Text(
            'Pinch to zoom • Swipe to rotate • Use arrows to walk',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport(String action) async {
    final design = ref.read(roomDesignProvider);
    final project = ref.read(projectProvider);
    final exportService = ref.read(exportServiceProvider);
    final storage = ref.read(projectStorageProvider);

    switch (action) {
      case 'screenshot':
        final image = await _screenshotController.capture();
        if (image != null) {
          final path = await exportService.saveScreenshot(image, design.name);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(path != null ? 'Saved to $path' : 'Screenshot captured')),
            );
          }
        }
      case 'pdf':
        final path = await exportService.generatePdf(design);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(path != null ? 'PDF saved to $path' : 'PDF export unavailable on web')),
          );
        }
      case 'project':
        final path = await storage.exportProjectFile(project);
        await exportService.shareProjectFile(project, path);
      case 'save':
        await storage.saveProject(project);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project saved')),
          );
        }
    }
  }
}
