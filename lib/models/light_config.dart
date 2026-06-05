import 'enums.dart';

class LightConfig {
  const LightConfig({
    required this.id,
    required this.type,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.positionZ = 0.9,
    this.brightness = 1.0,
    this.color = '#FFF8E1',
    this.temperature = LightTemperature.warmWhite,
    this.enabled = true,
  });

  final String id;
  final LightType type;
  final double positionX;
  final double positionY;
  final double positionZ;
  final double brightness;
  final String color;
  final LightTemperature temperature;
  final bool enabled;

  LightConfig copyWith({
    LightType? type,
    double? positionX,
    double? positionY,
    double? positionZ,
    double? brightness,
    String? color,
    LightTemperature? temperature,
    bool? enabled,
  }) {
    return LightConfig(
      id: id,
      type: type ?? this.type,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      positionZ: positionZ ?? this.positionZ,
      brightness: brightness ?? this.brightness,
      color: color ?? this.color,
      temperature: temperature ?? this.temperature,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'positionX': positionX,
        'positionY': positionY,
        'positionZ': positionZ,
        'brightness': brightness,
        'color': color,
        'temperature': temperature.name,
        'enabled': enabled,
      };

  factory LightConfig.fromJson(Map<String, dynamic> json) {
    return LightConfig(
      id: json['id'] as String,
      type: LightType.values.byName(json['type'] as String),
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
      positionZ: (json['positionZ'] as num?)?.toDouble() ?? 0.9,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      color: json['color'] as String? ?? '#FFF8E1',
      temperature: LightTemperature.values.byName(
        json['temperature'] as String? ?? 'warmWhite',
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
