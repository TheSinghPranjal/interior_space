import 'enums.dart';

class WallConfig {
  const WallConfig({
    required this.id,
    this.surfaceType = SurfaceType.solidColor,
    this.color = '#FFFFFF',
    this.texture = WallTexture.concrete,
    this.wallpaperPath,
    this.tileWallpaper = false,
    this.visibleFraction = 1.0,
    this.visibleAlign = WallVisibleAlign.start,
  });

  final WallId id;
  final SurfaceType surfaceType;
  final String color;
  final WallTexture texture;
  final String? wallpaperPath;
  final bool tileWallpaper;
  /// 0 = fully hidden, 0.5 = half length, 1 = full wall (custom wall mode only).
  final double visibleFraction;
  final WallVisibleAlign visibleAlign;

  bool get isFullyHidden => visibleFraction <= 0.001;
  bool get isPartial => visibleFraction > 0.001 && visibleFraction < 0.999;

  WallConfig copyWith({
    SurfaceType? surfaceType,
    String? color,
    WallTexture? texture,
    String? wallpaperPath,
    bool? tileWallpaper,
    bool clearWallpaper = false,
    double? visibleFraction,
    WallVisibleAlign? visibleAlign,
  }) {
    return WallConfig(
      id: id,
      surfaceType: surfaceType ?? this.surfaceType,
      color: color ?? this.color,
      texture: texture ?? this.texture,
      wallpaperPath: clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
      tileWallpaper: tileWallpaper ?? this.tileWallpaper,
      visibleFraction: visibleFraction ?? this.visibleFraction,
      visibleAlign: visibleAlign ?? this.visibleAlign,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'surfaceType': surfaceType.name,
        'color': color,
        'texture': texture.name,
        'wallpaperPath': wallpaperPath,
        'tileWallpaper': tileWallpaper,
        'visibleFraction': visibleFraction,
        'visibleAlign': visibleAlign.name,
      };

  factory WallConfig.fromJson(Map<String, dynamic> json) {
    return WallConfig(
      id: WallId.values.byName(json['id'] as String),
      surfaceType: SurfaceType.values.byName(
        json['surfaceType'] as String? ?? 'solidColor',
      ),
      color: json['color'] as String? ?? '#FFFFFF',
      texture: WallTexture.values.byName(
        json['texture'] as String? ?? 'concrete',
      ),
      wallpaperPath: json['wallpaperPath'] as String?,
      tileWallpaper: json['tileWallpaper'] as bool? ?? false,
      visibleFraction: (json['visibleFraction'] as num?)?.toDouble() ?? 1.0,
      visibleAlign: WallVisibleAlign.values.byName(
        json['visibleAlign'] as String? ?? 'start',
      ),
    );
  }

  static List<WallConfig> defaultWalls() {
    return WallId.values
        .map((id) => WallConfig(
              id: id,
              color: switch (id) {
                WallId.front => '#FFFFFF',
                WallId.back => '#9E9E9E',
                WallId.left => '#E8DCC8',
                WallId.right => '#4A90D9',
              },
            ))
        .toList();
  }
}
