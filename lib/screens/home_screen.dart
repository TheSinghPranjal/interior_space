import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/design_menu_action.dart';
import '../models/room_3d_export_images.dart';
import '../providers/apartment_placement_history_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/pdf_export_settings_provider.dart';
import '../providers/project_provider.dart';
import '../providers/room_design_provider.dart';
import '../services/apartment_share_service.dart';
import '../services/export_service.dart';
import '../services/project_storage_service.dart';
import '../services/public_download_saver.dart';
import '../widgets/apartment/apartment_space_view.dart';
import '../widgets/blueprint/blueprint_view.dart';
import '../widgets/editors/ceiling_editor.dart';
import '../widgets/editors/doors_editor.dart';
import '../widgets/editors/flooring_editor.dart';
import '../widgets/editors/furniture_editor.dart';
import '../widgets/editors/lighting_editor.dart';
import '../widgets/editors/room_setup_editor.dart';
import '../widgets/editors/walls_editor.dart';
import '../widgets/editors/windows_editor.dart';
import '../widgets/navigation/apartment_tabs_bar.dart';
import '../widgets/navigation/app_space_mode_toggle.dart';
import '../widgets/navigation/design_menu_fab.dart';
import '../widgets/navigation/room_tabs_bar.dart';
import '../widgets/three_d/room_3d_pdf_capture.dart';
import '../sketch/presentation/sketch_view.dart';
import 'ai_assist_screen.dart';
import 'editor_screen.dart';
import 'preview_3d_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MainNavTab _selectedTab = MainNavTab.room;

  @override
  void initState() {
    super.initState();
    _loadSavedProject();
  }

  Future<void> _loadSavedProject() async {
    final storage = ref.read(projectStorageProvider);
    final saved = await storage.loadCurrent();
    if (saved != null && mounted) {
      ref.read(projectProvider.notifier).load(saved);
      ref.read(apartmentPlacementHistoryProvider.notifier).clear();
    }
  }

  void _onTabSelected(int index) {
    final tab = MainNavTab.values[index];
    final isApartment = ref.read(appSpaceModeProvider) == AppSpaceMode.apartment;

    if (tab == MainNavTab.preview3d) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Preview3DScreen(apartmentMode: isApartment),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    setState(() => _selectedTab = tab);
  }

  void _onDesignMenuAction(DesignMenuAction action) {
    if (action == DesignMenuAction.blueprint) {
      setState(() => _selectedTab = MainNavTab.blueprint);
      return;
    }

    if (action == DesignMenuAction.roomSetup) {
      setState(() => _selectedTab = MainNavTab.room);
      return;
    }

    final editor = _editorForAction(action);
    if (editor == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => editor),
    );
  }

  EditorScreen? _editorForAction(DesignMenuAction action) {
    return switch (action) {
      DesignMenuAction.walls => const EditorScreen(
        title: 'Walls',
        icon: Icons.wallpaper_outlined,
        child: WallsEditor(),
      ),
      DesignMenuAction.flooring => const EditorScreen(
        title: 'Flooring',
        icon: Icons.grid_on_outlined,
        child: FlooringEditor(),
      ),
      DesignMenuAction.ceiling => const EditorScreen(
        title: 'Ceiling',
        icon: Icons.roofing_outlined,
        child: CeilingEditor(),
      ),
      DesignMenuAction.doors => const EditorScreen(
        title: 'Doors',
        icon: Icons.door_front_door_outlined,
        child: DoorsEditor(),
      ),
      DesignMenuAction.windows => const EditorScreen(
        title: 'Windows, Curtains & AC',
        icon: Icons.window_outlined,
        child: WindowsEditor(),
      ),
      DesignMenuAction.furniture => const EditorScreen(
        title: 'Furniture',
        icon: Icons.chair_outlined,
        child: FurnitureEditor(),
      ),
      DesignMenuAction.lighting => const EditorScreen(
        title: 'Lighting and Fan',
        icon: Icons.lightbulb_outline,
        child: LightingEditor(),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final activeRoom = ref.watch(roomDesignProvider);
    final appMode = ref.watch(appSpaceModeProvider);
    final isApartment = appMode == AppSpaceMode.apartment;
    final theme = Theme.of(context);

    ref.listen(projectProvider, (_, next) {
      ref.read(projectStorageProvider).saveCurrent(next);
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(
        context,
        theme: theme,
        project: project,
        activeRoom: activeRoom,
        appMode: appMode,
        isApartment: isApartment,
      ),
      body: Column(
        children: [
          const ApartmentTabsBar(),
          if (!isApartment) const RoomTabsBar(),
          Expanded(child: _buildBody(isApartment)),
        ],
      ),
      floatingActionButton: isApartment || _selectedTab == MainNavTab.sketch
          ? null
          : DesignMenuFab(onAction: _onDesignMenuAction),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.navBarBg,
          border: Border(
            top: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedTab.index,
          onDestinationSelected: _onTabSelected,
          destinations: [
            NavigationDestination(
              icon: Icon(isApartment ? Icons.apartment_outlined : Icons.meeting_room_outlined),
              selectedIcon: Icon(isApartment ? Icons.apartment : Icons.meeting_room),
              label: isApartment ? 'Apartment' : 'Room',
            ),
            const NavigationDestination(
              icon: Icon(Icons.architecture_outlined),
              selectedIcon: Icon(Icons.architecture),
              label: 'Blueprint',
            ),
            const NavigationDestination(
              icon: Icon(Icons.draw_outlined),
              selectedIcon: Icon(Icons.draw),
              label: 'Sketch',
            ),
            const NavigationDestination(
              icon: Icon(Icons.view_in_ar_outlined),
              selectedIcon: Icon(Icons.view_in_ar),
              label: '3D',
            ),
            const NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI Assist',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, {
        required ThemeData theme,
        required dynamic project,
        required dynamic activeRoom,
        required AppSpaceMode appMode,
        required bool isApartment,
      }) {
    final breadcrumb = isApartment
        ? '${project.apartmentLayout.name} · ${project.apartmentLayout.placements.length} spaces'
        : '${project.apartmentLayout.name} · ${activeRoom.name}';

    const double appBarHeight = 56.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactToggle = screenWidth < 720;

    return PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight),
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.appBarTheme.backgroundColor ?? AppTheme.surface,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SizedBox(
            height: appBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: (screenWidth * 0.34).clamp(120, 240),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appMode.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            breadcrumb,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: AppSpaceModeToggle(compact: compactToggle),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.save_outlined),
                          tooltip: 'Save project',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await ref.read(projectStorageProvider).saveProject(project);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Project saved')),
                              );
                            }
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'More actions',
                          onSelected: (value) {
                            switch (value) {
                              case 'reset':
                                isApartment
                                    ? _confirmResetApartment(context)
                                    : _confirmReset(context, activeRoom.name);
                              case 'export_room':
                                _exportCurrentRoomPdf(context);
                              case 'export_all_rooms':
                                _exportAllRoomsPdf(context);
                              case 'export_apartment_pdf':
                                _exportApartmentPdf(context);
                              case 'export_apartment':
                                _exportApartment(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh,
                                      size: 16, color: theme.colorScheme.error),
                                  const SizedBox(width: 12),
                                  Text(
                                    isApartment
                                        ? 'Reset apartment layout'
                                        : 'Reset current room',
                                    style: TextStyle(color: theme.colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            if (!isApartment) ...[
                              PopupMenuItem(
                                value: 'export_room',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf_outlined,
                                        size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    const Text('Export current room PDF'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export_all_rooms',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf_outlined,
                                        size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    const Text('Export all rooms PDF'),
                                  ],
                                ),
                              ),
                            ] else
                              PopupMenuItem(
                                value: 'export_apartment_pdf',
                                child: SizedBox(
                                  width: (MediaQuery.sizeOf(context).width * 0.55)
                                      .clamp(180, 280),
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf_outlined,
                                          size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Export PDF (${project.apartmentLayout.name})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export_apartment',
                                child: SizedBox(
                                  width: (MediaQuery.sizeOf(context).width * 0.55)
                                      .clamp(180, 280),
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file,
                                          size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Export apartment (${project.apartmentLayout.name})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isApartment) {
    final stackIndex = switch (_selectedTab) {
      MainNavTab.room => 0,
      MainNavTab.blueprint => 1,
      MainNavTab.sketch => 2,
      MainNavTab.preview3d => 1,
      MainNavTab.aiAssist => 3,
      MainNavTab.settings => 4,
    };

    if (isApartment) {
      return IndexedStack(
        index: stackIndex,
        children: const [
          ApartmentSpaceView(),
          ApartmentSpaceView(showBlueprintOnly: true),
          SketchView(),
          AiAssistPlaceholder(),
          SettingsScreen(),
        ],
      );
    }

    return IndexedStack(
      index: stackIndex,
      children: const [
        RoomSetupEditor(),
        BlueprintView(),
        SketchView(),
        AiAssistPlaceholder(),
        SettingsScreen(),
      ],
    );
  }

  void _confirmReset(BuildContext context, String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Room?'),
        content: Text(
          'This will reset "$roomName" to defaults. Other rooms are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(roomDesignProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCurrentRoomPdf(BuildContext context) async {
    final project = ref.read(projectProvider);
    final room = project.activeRoom;
    final exportService = ref.read(exportServiceProvider);
    final pdfSettings = ref.read(pdfExportSettingsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pdfSettings.shouldCapture3d
              ? 'Generating PDF with 3D preview...'
              : 'Generating PDF...',
        ),
        duration: Duration(seconds: pdfSettings.shouldCapture3d ? 60 : 15),
      ),
    );

    final render3dCapture = pdfSettings.shouldCapture3d
        ? await captureRoom3DImagesForPdf(
            context,
            pdfSettings: pdfSettings,
            scope: PdfExportCaptureScope.singleRoom,
          )
        : const ApartmentPdf3DCaptureResult();

    final path = await exportService.generatePdf(
      project,
      roomId: room.id,
      pdfSettings: pdfSettings,
      includeApartmentSections: false,
      render3dImagesByRoomIndex: render3dCapture.roomImages.isNotEmpty
          ? render3dCapture.roomImages
          : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null
              ? 'PDF saved to ${PublicDownloadSaver.displayPath(path)}'
              : 'Could not save PDF. Check storage permission.',
        ),
      ),
    );
  }

  Future<void> _exportAllRoomsPdf(BuildContext context) async {
    final project = ref.read(projectProvider);
    final exportService = ref.read(exportServiceProvider);
    final pdfSettings = ref.read(pdfExportSettingsProvider);
    final rooms = project.roomsForActiveApartment;

    if (rooms.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rooms to export')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pdfSettings.shouldCapture3d
              ? 'Generating PDF for ${rooms.length} rooms with 3D previews...'
              : 'Generating PDF for ${rooms.length} rooms...',
        ),
        duration: Duration(
          seconds: pdfSettings.shouldCapture3d ? 60 + rooms.length * 15 : 20,
        ),
      ),
    );

    final render3dCapture = pdfSettings.shouldCapture3d
        ? await captureRoom3DImagesForPdf(
            context,
            pdfSettings: pdfSettings,
            scope: PdfExportCaptureScope.allRooms,
          )
        : const ApartmentPdf3DCaptureResult();

    final path = await exportService.generatePdf(
      project,
      apartmentIndex: project.safeActiveApartmentIndex,
      pdfSettings: pdfSettings,
      includeApartmentSections: false,
      render3dImagesByRoomIndex: render3dCapture.roomImages.isNotEmpty
          ? render3dCapture.roomImages
          : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null
              ? 'PDF saved to ${PublicDownloadSaver.displayPath(path)}'
              : 'Could not save PDF. Check storage permission.',
        ),
      ),
    );
  }

  Future<void> _exportApartmentPdf(BuildContext context) async {
    final project = ref.read(projectProvider);
    final exportService = ref.read(exportServiceProvider);
    final pdfSettings = ref.read(pdfExportSettingsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pdfSettings.shouldCapture3d
              ? 'Generating PDF with floor plan and 3D previews...'
              : 'Generating PDF with apartment floor plan...',
        ),
        duration: Duration(seconds: pdfSettings.shouldCapture3d ? 90 : 20),
      ),
    );

    final render3dCapture = pdfSettings.shouldCapture3d
        ? await captureRoom3DImagesForPdf(
            context,
            pdfSettings: pdfSettings,
            scope: PdfExportCaptureScope.apartment,
          )
        : const ApartmentPdf3DCaptureResult();

    final path = await exportService.generatePdf(
      project,
      apartmentIndex: project.safeActiveApartmentIndex,
      pdfSettings: pdfSettings,
      includeApartmentSections: true,
      render3dImagesByRoomIndex: render3dCapture.roomImages.isNotEmpty
          ? render3dCapture.roomImages
          : null,
      apartmentTopView3d: render3dCapture.apartmentTopView,
      apartmentFrontView3d: render3dCapture.apartmentFrontView,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null
              ? 'PDF saved to ${PublicDownloadSaver.displayPath(path)}'
              : 'Could not save PDF. Check storage permission.',
        ),
      ),
    );
  }

  Future<void> _exportApartment(BuildContext context) async {
    final project = ref.read(projectProvider);
    final layout = project.apartmentLayout;
    final rooms = project.roomsForActiveApartment;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(apartmentShareServiceProvider).shareApartment(
            apartment: layout,
            rooms: rooms,
          );
    } on ApartmentShareException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export apartment: $e')),
      );
    }
  }

  void _confirmResetApartment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Apartment Layout?'),
        content: Text(
          'This will remove all rooms from "${ref.read(projectProvider).apartmentLayout.name}" '
              'blueprint. Your individual room designs are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(projectProvider.notifier).resetApartmentLayout();
              ref.read(apartmentPlacementHistoryProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}