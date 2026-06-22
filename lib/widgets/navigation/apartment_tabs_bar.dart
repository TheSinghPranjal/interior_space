import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/apartment_placement_history_provider.dart';
import '../../providers/project_provider.dart';
import '../common/confirm_delete_dialog.dart';

class ApartmentTabsBar extends ConsumerWidget {
  const ApartmentTabsBar({super.key});

  static const _addButtonColor = Color(0xFFE85D8A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final apartments = project.apartmentsOrDefault;
    final activeIndex = project.safeActiveApartmentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: apartments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final apartment = apartments[index];
                  final isActive = index == activeIndex;
                  return _ApartmentTab(
                    label: apartment.name,
                    color: ApartmentBuildingIcon.colorForIndex(index),
                    isActive: isActive,
                    canDelete: project.canRemoveApartment,
                    onTap: () {
                      ref.read(apartmentPlacementHistoryProvider.notifier).clear();
                      ref.read(projectProvider.notifier).setActiveApartment(index);
                    },
                    onDelete: () => _confirmDeleteApartment(
                      context,
                      ref,
                      index,
                      apartment.name,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: project.canAddApartment
                    ? _addButtonColor
                    : _addButtonColor.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                elevation: project.canAddApartment ? 2 : 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: project.canAddApartment
                      ? () {
                          ref
                              .read(apartmentPlacementHistoryProvider.notifier)
                              .clear();
                          ref.read(projectProvider.notifier).addApartment();
                        }
                      : null,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withValues(
                        alpha: project.canAddApartment ? 1 : 0.6,
                      ),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteApartment(
    BuildContext context,
    WidgetRef ref,
    int index,
    String apartmentName,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Apartment?',
      message:
          'Remove "$apartmentName", all its rooms, and floor plan placements? '
          'This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;

    ref.read(apartmentPlacementHistoryProvider.notifier).clear();
    ref.read(projectProvider.notifier).removeApartment(index);
  }
}

class _ApartmentTab extends StatelessWidget {
  const _ApartmentTab({
    required this.label,
    required this.color,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final Color color;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? Colors.white : Colors.transparent,
      elevation: isActive ? 3 : 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minWidth: 88, maxWidth: 110),
          padding: EdgeInsets.only(
            left: 8,
            right: canDelete ? 2 : 8,
            top: 6,
            bottom: 4,
          ),
          decoration: isActive
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.5),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ApartmentBuildingIcon(color: color, size: 38),
                  if (canDelete)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
