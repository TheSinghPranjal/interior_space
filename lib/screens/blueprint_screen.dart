import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/blueprint/blueprint_view.dart';

/// Standalone blueprint screen (also embedded in [HomeScreen]).
class BlueprintScreen extends ConsumerWidget {
  const BlueprintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blueprint View')),
      body: const BlueprintView(),
    );
  }
}
