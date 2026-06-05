import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/room_design_provider.dart';
import '../services/project_storage_service.dart';
import '../widgets/editors/ceiling_editor.dart';
import '../widgets/editors/cupboards_editor.dart';
import '../widgets/editors/doors_editor.dart';
import '../widgets/editors/flooring_editor.dart';
import '../widgets/editors/furniture_editor.dart';
import '../widgets/editors/lighting_editor.dart';
import '../widgets/editors/room_setup_editor.dart';
import '../widgets/editors/walls_editor.dart';
import '../widgets/editors/windows_editor.dart';
import 'blueprint_screen.dart';
import 'preview_3d_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _sections = [
    _Section('Room Setup', Icons.square_foot, RoomSetupEditor()),
    _Section('Blueprint', Icons.architecture, null),
    _Section('Walls', Icons.wallpaper, WallsEditor()),
    _Section('Flooring', Icons.grid_on, FlooringEditor()),
    _Section('Ceiling', Icons.roofing, CeilingEditor()),
    _Section('Doors', Icons.door_front_door, DoorsEditor()),
    _Section('Windows', Icons.window, WindowsEditor()),
    _Section('Cupboards', Icons.kitchen, CupboardsEditor()),
    _Section('Furniture', Icons.chair, FurnitureEditor()),
    _Section('Lighting', Icons.lightbulb, LightingEditor()),
    _Section('3D Preview', Icons.view_in_ar, null),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedProject();
  }

  Future<void> _loadSavedProject() async {
    final storage = ref.read(projectStorageProvider);
    final saved = await storage.loadCurrent();
    if (saved != null && mounted) {
      ref.read(roomDesignProvider.notifier).load(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(roomDesignProvider);
    final section = _sections[_selectedIndex];

    ref.listen(roomDesignProvider, (_, next) {
      ref.read(projectStorageProvider).saveCurrent(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Interior Space'),
            Text(
              design.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: () async {
              await ref.read(projectStorageProvider).saveProject(design);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project saved')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: _buildBody(section),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          final sec = _sections[index];
          if (sec.label == 'Blueprint') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlueprintScreen()),
            );
            return;
          }
          if (sec.label == '3D Preview') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Preview3DScreen(),
                fullscreenDialog: true,
              ),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: _sections
            .map(
              (s) => NavigationDestination(
                icon: Icon(s.icon),
                label: s.label.split(' ').first,
              ),
            )
            .toList(),
      ),
      floatingActionButton: _selectedIndex == 1 || _selectedIndex == 10
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlueprintScreen()),
                );
              },
              icon: const Icon(Icons.architecture),
              label: const Text('Blueprint'),
            ),
    );
  }

  Widget _buildBody(_Section section) {
    if (section.widget == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(section.icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              section.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Tap the navigation item to open'),
          ],
        ),
      );
    }
    return section.widget!;
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Room?'),
        content: const Text('This will reset all customizations to defaults.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
}

class _Section {
  const _Section(this.label, this.icon, this.widget);

  final String label;
  final IconData icon;
  final Widget? widget;
}
