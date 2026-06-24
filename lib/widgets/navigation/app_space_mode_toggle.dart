import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_mode_provider.dart';

/// Interior / Apartment mode switch for the app bar.
class AppSpaceModeToggle extends ConsumerWidget {
  const AppSpaceModeToggle({super.key, this.compact = false});

  final bool compact;

  static const _iconTabWidth = 40.0;
  static const _iconBarHeight = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appSpaceModeProvider);

    if (compact) {
      return _IconModeBar(appMode: appMode);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      child: SegmentedButton<AppSpaceMode>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        segments: const [
          ButtonSegment(
            value: AppSpaceMode.interior,
            label: Text('Interior'),
            icon: Icon(Icons.meeting_room_outlined, size: 15),
          ),
          ButtonSegment(
            value: AppSpaceMode.apartment,
            label: Text('Apartment'),
            icon: Icon(Icons.apartment_outlined, size: 15),
          ),
        ],
        selected: {appMode},
        onSelectionChanged: (selection) {
          ref.read(appSpaceModeProvider.notifier).state = selection.first;
        },
      ),
    );
  }
}

class _IconModeBar extends ConsumerWidget {
  const _IconModeBar({required this.appMode});

  final AppSpaceMode appMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: AppSpaceModeToggle._iconBarHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconTab(
              selected: appMode == AppSpaceMode.interior,
              icon: Icons.meeting_room_outlined,
              tooltip: 'Interior Space',
              onTap: () =>
                  ref.read(appSpaceModeProvider.notifier).state = AppSpaceMode.interior,
            ),
            _IconTab(
              selected: appMode == AppSpaceMode.apartment,
              icon: Icons.apartment_outlined,
              tooltip: 'Apartment Space',
              onTap: () =>
                  ref.read(appSpaceModeProvider.notifier).state = AppSpaceMode.apartment,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTab extends StatelessWidget {
  const _IconTab({
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? cs.secondaryContainer : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpaceModeToggle._iconTabWidth,
            height: AppSpaceModeToggle._iconBarHeight,
            child: Icon(
              icon,
              size: 20,
              color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
