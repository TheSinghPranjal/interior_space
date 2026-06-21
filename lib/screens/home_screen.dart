import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/design_menu_action.dart';
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

  void _toggleAppSpaceMode() {
    final current = ref.read(appSpaceModeProvider);
    ref.read(appSpaceModeProvider.notifier).state =
        current == AppSpaceMode.interior ? AppSpaceMode.apartment : AppSpaceMode.interior;
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
          icon: Icons.wallpaper,
          child: WallsEditor(),
        ),
      DesignMenuAction.flooring => const EditorScreen(
          title: 'Flooring',
          icon: Icons.grid_on,
          child: FlooringEditor(),
        ),
      DesignMenuAction.ceiling => const EditorScreen(
          title: 'Ceiling',
          icon: Icons.roofing,
          child: CeilingEditor(),
        ),
      DesignMenuAction.doors => const EditorScreen(
          title: 'Doors',
          icon: Icons.door_front_door,
          child: DoorsEditor(),
        ),
      DesignMenuAction.windows => const EditorScreen(
          title: 'Windows, Curtains & AC',
          icon: Icons.window,
          child: WindowsEditor(),
        ),
      DesignMenuAction.cupboards => const EditorScreen(
          title: 'Cupboards',
          icon: Icons.kitchen,
          child: CupboardsEditor(),
        ),
      DesignMenuAction.furniture => const EditorScreen(
          title: 'Furniture',
          icon: Icons.chair,
          child: FurnitureEditor(),
        ),
      DesignMenuAction.lighting => const EditorScreen(
          title: 'Lighting and Fan',
          icon: Icons.lightbulb,
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

    ref.listen(projectProvider, (_, next) {
      ref.read(projectStorageProvider).saveCurrent(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(appMode.title),
            Text(
              isApartment
                  ? '${project.apartmentLayout.placements.length} rooms on plan'
                  : activeRoom.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isApartment ? Icons.meeting_room_outlined : Icons.apartment_outlined),
            tooltip: isApartment ? 'Switch to Interior Space' : 'Switch to Apartment Space',
            onPressed: _toggleAppSpaceMode,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: () async {
              await ref.read(projectStorageProvider).saveProject(project);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project saved')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isApartment ? 'Reset apartment layout' : 'Reset current room',
            onPressed: () => isApartment
                ? _confirmResetApartment(context)
                : _confirmReset(context, activeRoom.name),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isApartment) const RoomTabsBar(),
          Expanded(child: _buildBody(isApartment)),
        ],
      ),
      floatingActionButton: isApartment ? null : DesignMenuFab(onAction: _onDesignMenuAction),
      bottomNavigationBar: NavigationBar(
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
        content: const Text(
          'This will remove all rooms from the apartment blueprint. '
          'Your individual room designs are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(projectProvider.notifier).resetApartmentLayout();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
