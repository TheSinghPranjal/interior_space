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
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 3),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              padding: const EdgeInsets.only(right: 8),
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
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.add,
                      color: Colors.white.withValues(
                        alpha: project.canAddApartment ? 1 : 0.6,
                      ),
                      size: 22,
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 76, maxWidth: 100),
          padding: EdgeInsets.only(
            left: 6,
            right: canDelete ? 2 : 6,
            top: 4,
            bottom: 2,
          ),
          decoration: isActive
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                  ApartmentBuildingIcon(color: color, size: 28),
                  if (canDelete)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
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
