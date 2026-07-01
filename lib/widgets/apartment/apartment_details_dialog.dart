import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/apartment_details.dart';
import '../../providers/project_provider.dart';

Future<void> showApartmentDetailsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ApartmentDetailsDialog(),
  );
}

class ApartmentDetailsDialog extends ConsumerStatefulWidget {
  const ApartmentDetailsDialog({super.key});

  @override
  ConsumerState<ApartmentDetailsDialog> createState() => _ApartmentDetailsDialogState();
}

class _ApartmentDetailsDialogState extends ConsumerState<ApartmentDetailsDialog> {
  late final TextEditingController _unitTypeController;
  late final TextEditingController _towerController;
  late final TextEditingController _superBuiltUpController;
  late final TextEditingController _carpetAreaController;
  late final TextEditingController _blockNameController;
  late final TextEditingController _blockController;
  late final TextEditingController _descriptionController;
  ApartmentFacing? _facing;

  @override
  void initState() {
    super.initState();
    final details = ref.read(projectProvider).apartmentLayout.details;
    _unitTypeController = TextEditingController(text: details.unitType);
    _towerController = TextEditingController(text: details.tower);
    _superBuiltUpController = TextEditingController(text: details.superBuiltUpArea);
    _carpetAreaController = TextEditingController(text: details.carpetArea);
    _blockNameController = TextEditingController(text: details.blockName);
    _blockController = TextEditingController(text: details.block);
    _descriptionController = TextEditingController(text: details.description);
    _facing = details.facing;
  }

  @override
  void dispose() {
    _unitTypeController.dispose();
    _towerController.dispose();
    _superBuiltUpController.dispose();
    _carpetAreaController.dispose();
    _blockNameController.dispose();
    _blockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(projectProvider.notifier).updateApartmentDetails(
          ApartmentDetails(
            unitType: _unitTypeController.text.trim(),
            tower: _towerController.text.trim(),
            superBuiltUpArea: _superBuiltUpController.text.trim(),
            carpetArea: _carpetAreaController.text.trim(),
            blockName: _blockNameController.text.trim(),
            block: _blockController.text.trim(),
            facing: _facing,
            description: _descriptionController.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Apartment Information'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add property details for this apartment. These appear in apartment PDF exports.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _unitTypeController,
                decoration: const InputDecoration(
                  labelText: 'Unit Type',
                  hintText: 'e.g. 3 BHK, Penthouse',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _towerController,
                decoration: const InputDecoration(
                  labelText: 'Tower',
                  hintText: 'e.g. Tower A',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _superBuiltUpController,
                decoration: const InputDecoration(
                  labelText: 'Super Built-Up Area',
                  hintText: 'e.g. 1450 sq ft',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _carpetAreaController,
                decoration: const InputDecoration(
                  labelText: 'Carpet Area',
                  hintText: 'e.g. 1100 sq ft',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _blockNameController,
                decoration: const InputDecoration(
                  labelText: 'Block Name',
                  hintText: 'e.g. Emerald Block',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _blockController,
                decoration: const InputDecoration(
                  labelText: 'Block',
                  hintText: 'e.g. B, Wing 2',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<ApartmentFacing?>(
                initialValue: _facing,
                decoration: const InputDecoration(labelText: 'Facing'),
                hint: const Text('Select facing'),
                items: [
                  const DropdownMenuItem<ApartmentFacing?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  ...ApartmentFacing.values.map(
                    (facing) => DropdownMenuItem(
                      value: facing,
                      child: Text(facing.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _facing = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Additional notes about this apartment',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
