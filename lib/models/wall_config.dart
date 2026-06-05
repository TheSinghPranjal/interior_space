import 'enums.dart';

class WallConfig {
  const WallConfig({
    required this.id,
    this.surfaceType = SurfaceType.solidColor,
    this.color = '#FFFFFF',
    this.texture = WallTexture.concrete,
    this.wallpaperPath,
    this.tileWallpaper = false,
  });

  final WallId id;
  final SurfaceType surfaceType;
  final String color;
  final WallTexture texture;
  final String? wallpaperPath;
  final bool tileWallpaper;

  WallConfig copyWith({
    SurfaceType? surfaceType,
    String? color,
    WallTexture? texture,
    String? wallpaperPath,
    bool? tileWallpaper,
    bool clearWallpaper = false,
  }) {
    return WallConfig(
      id: id,
      surfaceType: surfaceType ?? this.surfaceType,
      color: color ?? this.color,
      texture: texture ?? this.texture,
      wallpaperPath: clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
      tileWallpaper: tileWallpaper ?? this.tileWallpaper,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'surfaceType': surfaceType.name,
        'color': color,
        'texture': texture.name,
        'wallpaperPath': wallpaperPath,
        'tileWallpaper': tileWallpaper,
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
