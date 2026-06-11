class FanConfig {
  const FanConfig({
    required this.id,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.height = 0.95,
    this.color = '#ECEFF1',
  });

  final String id;
  final double positionX;
  final double positionY;
  /// Normalized height from floor (0–1), same as ceiling lights — 1.0 is at the ceiling.
  final double height;
  final String color;

  FanConfig copyWith({
    double? positionX,
    double? positionY,
    double? height,
    String? color,
  }) {
    return FanConfig(
      id: id,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      height: height ?? this.height,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'positionX': positionX,
        'positionY': positionY,
        'height': height,
        'color': color,
      };

  factory FanConfig.fromJson(Map<String, dynamic> json) {
    return FanConfig(
      id: json['id'] as String,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
      height: (json['height'] as num?)?.toDouble() ?? 0.95,
      color: json['color'] as String? ?? '#ECEFF1',
    );
  }
}
