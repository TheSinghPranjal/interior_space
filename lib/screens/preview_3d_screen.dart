import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/room_3d_export_images.dart';
import '../providers/app_mode_provider.dart';
import '../providers/project_provider.dart';
import '../providers/room_design_provider.dart';
import '../services/export_service.dart';
import '../services/project_storage_service.dart';
import '../services/public_download_saver.dart';
import '../widgets/three_d/room_3d_viewer.dart';

class Preview3DScreen extends ConsumerStatefulWidget {
  const Preview3DScreen({super.key, this.apartmentMode = false});

  final bool apartmentMode;

  @override
  ConsumerState<Preview3DScreen> createState() => _Preview3DScreenState();
}

class _Preview3DScreenState extends ConsumerState<Preview3DScreen> {
  final _screenshotController = ScreenshotController();
  Future<Map<int, Room3DExportImages>> Function()? _capture3dAllRooms;

  static const _immersiveBg = Color(0xFF121816);

  @override
  Widget build(BuildContext context) {
    final isApartment = widget.apartmentMode ||
        ref.watch(appSpaceModeProvider) == AppSpaceMode.apartment;
    final design = ref.watch(roomDesignProvider);
    final project = ref.watch(projectProvider);
    final title = isApartment ? 'Apartment Preview' : design.name;

    return Scaffold(
      backgroundColor: _immersiveBg,
      appBar: AppBar(
        backgroundColor: _immersiveBg,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              isApartment
                  ? '${project.apartmentLayout.placements.length} rooms'
                  : '3D room preview',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (!isApartment)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
              tooltip: 'Export',
              onPressed: () => _showExportSheet(context),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Room3DViewer(
          showControls: true,
          apartmentMode: isApartment,
          onCaptureReady: (capture) => _capture3dAllRooms = capture,
        ),
      ),
      bottomNavigationBar: Container(
        color: _immersiveBg,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 12, color: Colors.white.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Text(
                isApartment
                    ? 'Pinch to zoom · Swipe to rotate · Tap info for dimensions'
                    : 'Pinch to zoom · Swipe to rotate',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Export', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Save screenshot'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('screenshot');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Export PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share project'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('project');
                },
              ),
              ListTile(
                leading: Icon(Icons.save_outlined, color: AppTheme.primary),
                title: const Text('Save project'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('save');
                },
              ),
            ],
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
              SnackBar(
                content: Text(
                  path != null
                      ? 'Screenshot saved to ${PublicDownloadSaver.displayPath(path)}'
                      : 'Could not save screenshot to Downloads. Check storage permission.',
                ),
              ),
            );
          }
        }
        break;
      case 'pdf':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating PDF with 3D previews for all rooms...'),
              duration: Duration(seconds: 60),
            ),
          );
        }
        final render3dByRoom = await _capture3dAllRooms?.call() ?? {};
        final path = await exportService.generatePdf(
          project,
          render3dImagesByRoomIndex:
              render3dByRoom.isNotEmpty ? render3dByRoom : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                path != null
                    ? 'PDF saved to ${PublicDownloadSaver.displayPath(path)}'
                    : 'Could not save PDF to Downloads. Check storage permission.',
              ),
            ),
          );
        }
        break;
      case 'project':
        final path = await storage.exportProjectFile(project);
        await exportService.shareProjectFile(project, path);
        break;
      case 'save':
        await storage.saveProject(project);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project saved')),
          );
        }
        break;
    }
  }
}
