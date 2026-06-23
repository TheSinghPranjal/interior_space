import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../models/design_menu_action.dart';
import '../providers/apartment_placement_history_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/project_provider.dart';
import '../providers/room_design_provider.dart';
import '../services/project_storage_service.dart';
import '../widgets/apartment/apartment_space_view.dart';
import '../widgets/blueprint/blueprint_view.dart';
import '../widgets/editors/ceiling_editor.dart';
import '../widgets/editors/cupboards_editor.dart';
import '../widgets/editors/doors_editor.dart';
import '../widgets/editors/flooring_editor.dart';
import '../widgets/editors/furniture_editor.dart';
import '../widgets/editors/lighting_editor.dart';
import '../widgets/editors/room_setup_editor.dart';
import '../widgets/editors/walls_editor.dart';
import '../widgets/editors/windows_editor.dart';
import '../widgets/navigation/apartment_tabs_bar.dart';
import '../widgets/navigation/design_menu_fab.dart';
import '../widgets/navigation/room_tabs_bar.dart';
import 'ai_assist_screen.dart';
import 'editor_screen.dart';
import 'preview_3d_screen.dart';

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
      DesignMenuAction.cupboards => const EditorScreen(
          title: 'Cupboards',
          icon: Icons.kitchen_outlined,
          child: CupboardsEditor(),
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
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appMode.title, style: theme.textTheme.titleLarge),
            Text(
              isApartment
                  ? '${project.apartmentLayout.name} · ${project.apartmentLayout.placements.length} on plan'
                  : '${project.apartmentLayout.name} · ${activeRoom.name}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: SegmentedButton<AppSpaceMode>(
              segments: const [
                ButtonSegment(
                  value: AppSpaceMode.interior,
                  label: Text('Interior'),
                  icon: Icon(Icons.meeting_room_outlined, size: 18),
                ),
                ButtonSegment(
                  value: AppSpaceMode.apartment,
                  label: Text('Apartment'),
                  icon: Icon(Icons.apartment_outlined, size: 18),
                ),
              ],
              selected: {appMode},
              onSelectionChanged: (selection) {
                ref.read(appSpaceModeProvider.notifier).state = selection.first;
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save project',
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
              if (value == 'reset') {
                isApartment
                    ? _confirmResetApartment(context)
                    : _confirmReset(context, activeRoom.name);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      isApartment ? 'Reset apartment layout' : 'Reset current room',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const ApartmentTabsBar(),
          if (!isApartment) const RoomTabsBar(),
          Expanded(child: _buildBody(isApartment)),
        ],
      ),
      floatingActionButton: isApartment ? null : DesignMenuFab(onAction: _onDesignMenuAction),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'Room',
            ),
            NavigationDestination(
              icon: Icon(Icons.architecture_outlined),
              selectedIcon: Icon(Icons.architecture),
              label: 'Blueprint',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_in_ar_outlined),
              selectedIcon: Icon(Icons.view_in_ar),
              label: '3D',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI Assist',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isApartment) {
    if (isApartment) {
      return switch (_selectedTab) {
        MainNavTab.room => const ApartmentSpaceView(),
        MainNavTab.blueprint => const ApartmentSpaceView(showBlueprintOnly: true),
        MainNavTab.preview3d => const ApartmentSpaceView(showBlueprintOnly: true),
        MainNavTab.aiAssist => const AiAssistPlaceholder(),
      };
    }

    return switch (_selectedTab) {
      MainNavTab.room => const RoomSetupEditor(),
      MainNavTab.blueprint => const BlueprintView(),
      MainNavTab.preview3d => const RoomSetupEditor(),
      MainNavTab.aiAssist => const AiAssistPlaceholder(),
    };
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
