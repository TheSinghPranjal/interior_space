import 'enums.dart';

class WallConfig {
  const WallConfig({
    required this.wallIndex,
    this.id = WallId.front,
    this.surfaceType = SurfaceType.solidColor,
    this.color = '#FFFFFF',
    this.texture = WallTexture.concrete,
    this.wallpaperPath,
    this.tileWallpaper = false,
    this.visibleFraction = 1.0,
    this.visibleAlign = WallVisibleAlign.start,
    this.barrierType = WallBarrierType.solid,
  });

  /// 0-based wall index. Wall N = edge from vertex N to vertex N+1.
  final int wallIndex;
  /// Legacy rectangular wall id (kept for JSON compatibility).
  final WallId id;
  final SurfaceType surfaceType;
  final String color;
  final WallTexture texture;
  final String? wallpaperPath;
  final bool tileWallpaper;
  /// 0 = fully hidden, 0.5 = half length, 1 = full wall (custom wall mode only).
  final double visibleFraction;
  final WallVisibleAlign visibleAlign;
  /// Custom wall mode: replace solid wall with fence or balcony railing.
  final WallBarrierType barrierType;

  int get displayNumber => wallIndex + 1;

  bool get isFullyHidden => visibleFraction <= 0.001;
  bool get isPartial => visibleFraction > 0.001 && visibleFraction < 0.999;
  bool get isBarrier => barrierType != WallBarrierType.solid;

  WallConfig copyWith({
    int? wallIndex,
    WallId? id,
    SurfaceType? surfaceType,
    String? color,
    WallTexture? texture,
    String? wallpaperPath,
    bool? tileWallpaper,
    bool clearWallpaper = false,
    double? visibleFraction,
    WallVisibleAlign? visibleAlign,
    WallBarrierType? barrierType,
  }) {
    return WallConfig(
      wallIndex: wallIndex ?? this.wallIndex,
      id: id ?? this.id,
      surfaceType: surfaceType ?? this.surfaceType,
      color: color ?? this.color,
      texture: texture ?? this.texture,
      wallpaperPath: clearWallpaper ? null : (wallpaperPath ?? this.wallpaperPath),
      tileWallpaper: tileWallpaper ?? this.tileWallpaper,
      visibleFraction: visibleFraction ?? this.visibleFraction,
      visibleAlign: visibleAlign ?? this.visibleAlign,
      barrierType: barrierType ?? this.barrierType,
    );
  }

  Map<String, dynamic> toJson() => {
        'wallIndex': wallIndex,
        'id': id.name,
        'surfaceType': surfaceType.name,
        'color': color,
        'texture': texture.name,
        'wallpaperPath': wallpaperPath,
        'tileWallpaper': tileWallpaper,
        'visibleFraction': visibleFraction,
        'visibleAlign': visibleAlign.name,
        'barrierType': barrierType.name,
      };

  factory WallConfig.fromJson(Map<String, dynamic> json) {
    final id = WallId.values.byName(json['id'] as String);
    return WallConfig(
      wallIndex: (json['wallIndex'] as num?)?.toInt() ?? WallId.values.indexOf(id),
      id: id,
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
      barrierType: WallBarrierType.values.byName(
        json['barrierType'] as String? ?? 'solid',
      ),
    );
  }

  static List<WallConfig> defaultWalls({int count = 4}) {
    return List.generate(count, (index) {
      final id = WallId.values[index % WallId.values.length];
      return WallConfig(
        wallIndex: index,
        id: id,
        color: switch (id) {
          WallId.front => '#FFFFFF',
          WallId.back => '#9E9E9E',
          WallId.left => '#E8DCC8',
          WallId.right => '#4A90D9',
        },
      );
    });
  }

  static List<WallConfig> syncWallCount(List<WallConfig> existing, int count) {
    if (count < 1) return defaultWalls();
    final result = <WallConfig>[];
    for (var i = 0; i < count; i++) {
      final prev = existing.cast<WallConfig?>().elementAtOrNull(i);
      result.add(
        prev?.copyWith(wallIndex: i) ??
            WallConfig(
              wallIndex: i,
              id: WallId.values[i % WallId.values.length],
              color: _paletteColor(i),
            ),
      );
    }
    return result;
  }

  static String _paletteColor(int index) {
    const palette = [
      '#FFFFFF',
      '#E8DCC8',
      '#9E9E9E',
      '#4A90D9',
      '#B0BEC5',
      '#A1887F',
      '#90CAF9',
      '#CFD8DC',
    ];
    return palette[index % palette.length];
  }
}

extension _ListElementAtOrNull<E> on List<E> {
  E? elementAtOrNull(int index) =>
      index >= 0 && index < length ? this[index] : null;
}
