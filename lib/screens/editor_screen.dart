import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      body: child,
    );
  }
}
