import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/fan_config.dart';
import '../../models/light_config.dart';
import '../../providers/room_design_provider.dart';
import '../common/color_picker_field.dart';
import '../common/editor_item_card.dart';
import '../common/section_card.dart';

class LightingEditor extends ConsumerWidget {
  const LightingEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lights = ref.watch(roomDesignProvider).lights;
    final fans = ref.watch(roomDesignProvider).fans;

    return ListView(
      children: [
        SectionCard(
          title: 'Lighting',
          subtitle: 'Real-time lighting affects walls, floor & furniture',
          trailing: PopupMenuButton<LightType>(
            icon: const Icon(Icons.add),
            onSelected: (type) => ref.read(roomDesignProvider.notifier).addLight(type: type),
            itemBuilder: (context) => LightType.values
                .map((t) => PopupMenuItem(value: t, child: Text(_lightLabel(t))))
                .toList(),
          ),
          child: lights.isEmpty
              ? const Text('No lights added.')
              : Column(
                  children: lights.map((l) => _LightCard(light: l)).toList(),
                ),
        ),
        SectionCard(
          title: 'Ceiling Fans',
          subtitle: 'Ceiling-mounted fans • Position on room ceiling',
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(roomDesignProvider.notifier).addFan(),
          ),
          child: fans.isEmpty
              ? const Text('No ceiling fans added. Tap + to add a fan.')
              : Column(
                  children: fans.map((f) => _FanCard(fan: f)).toList(),
                ),
        ),
      ],
    );
  }

  String _lightLabel(LightType t) => switch (t) {
        LightType.ceiling => 'Ceiling Light',
        LightType.spot => 'Spot Light',
        LightType.ledStrip => 'LED Strip',
        LightType.chandelier => 'Chandelier',
        LightType.wall => 'Wall Light',
      };
}

class _LightCard extends ConsumerWidget {
  const _LightCard({required this.light});

  final LightConfig light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EditorItemCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _label(light.type),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Switch(
                value: light.enabled,
                onChanged: (v) => ref.read(roomDesignProvider.notifier).updateLight(
                      light.copyWith(enabled: v),
                    ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => ref.read(roomDesignProvider.notifier).removeLight(light.id),
              ),
            ],
          ),
            _Slider(label: 'Brightness', value: light.brightness, min: 0.2, max: 2, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(brightness: v));
            }),
            _Slider(label: 'Position X', value: light.positionX, min: 0, max: 1, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(positionX: v));
            }),
            _Slider(label: 'Position Y', value: light.positionY, min: 0, max: 1, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(positionY: v));
            }),
            _Slider(label: 'Height', value: light.positionZ, min: 0.3, max: 1, onChanged: (v) {
              ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(positionZ: v));
            }),
            ColorPickerField(
              label: 'Light Color',
              colorHex: light.color,
              onChanged: (c) => ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(color: c)),
            ),
            DropdownButtonFormField<LightTemperature>(
              value: light.temperature,
              decoration: const InputDecoration(labelText: 'Temperature'),
              items: LightTemperature.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_tempLabel(t))))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  ref.read(roomDesignProvider.notifier).updateLight(light.copyWith(temperature: t));
                }
              },
            ),
          ],
      ),
    );
  }

  String _label(LightType t) => switch (t) {
        LightType.ceiling => 'Ceiling Light',
        LightType.spot => 'Spot Light',
        LightType.ledStrip => 'LED Strip',
        LightType.chandelier => 'Chandelier',
        LightType.wall => 'Wall Light',
      };

  String _tempLabel(LightTemperature t) => switch (t) {
        LightTemperature.warmWhite => 'Warm White',
        LightTemperature.coolWhite => 'Cool White',
        LightTemperature.neutralWhite => 'Neutral White',
      };
}

class _FanCard extends ConsumerWidget {
  const _FanCard({required this.fan});

  final FanConfig fan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomDesignProvider.notifier);

    return EditorItemCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.air, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ceiling Fan',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => notifier.removeFan(fan.id),
              ),
            ],
          ),
            _Slider(
              label: 'Position X',
              value: fan.positionX,
              min: 0,
              max: 1,
              onChanged: (v) => notifier.updateFan(fan.copyWith(positionX: v)),
            ),
            _Slider(
              label: 'Position Y',
              value: fan.positionY,
              min: 0,
              max: 1,
              onChanged: (v) => notifier.updateFan(fan.copyWith(positionY: v)),
            ),
            _Slider(
              label: 'Height',
              value: fan.height,
              min: 0.85,
              max: 1,
              onChanged: (v) => notifier.updateFan(fan.copyWith(height: v)),
            ),
            ColorPickerField(
              label: 'Fan Color',
              colorHex: fan.color,
              onChanged: (c) => notifier.updateFan(fan.copyWith(color: c)),
            ),
          ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
