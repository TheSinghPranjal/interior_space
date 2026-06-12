import 'package:flutter/material.dart';

class ItemEditorHeader extends StatelessWidget {

  const ItemEditorHeader({
    super.key,
    required this.title,
    required this.editingEnabled,
    required this.onToggleEdit,
    required this.onDelete,
    this.icon,
  });


  final String title;
  final IconData? icon;
  final bool editingEnabled;
  final VoidCallback onToggleEdit;
  final VoidCallback onDelete;



  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: Icon(editingEnabled ? Icons.edit_off_outlined : Icons.edit_outlined),
          tooltip: editingEnabled ? 'Lock parameters' : 'Edit parameters',
          color: editingEnabled ? Colors.orange.shade800 : null,
          onPressed: onToggleEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
