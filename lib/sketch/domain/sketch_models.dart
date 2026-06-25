import 'dart:ui';

import 'sketch_tool.dart';

/// Normalized point in canvas space (0–1).
class SketchPoint {
  const SketchPoint(this.x, this.y);

  final double x;
  final double y;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory SketchPoint.fromJson(Map<String, dynamic> json) => SketchPoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

class SketchStroke {
  const SketchStroke({
    required this.id,
    required this.points,
    required this.colorArgb,
    required this.width,
    this.opacity = 1,
    this.isHighlighter = false,
    this.layerId = 'drawing',
    this.locked = false,
    this.visible = true,
  });

  final String id;
  final List<SketchPoint> points;
  final int colorArgb;
  final double width;
  final double opacity;
  final bool isHighlighter;
  final String layerId;
  final bool locked;
  final bool visible;

  SketchStroke copyWith({
    List<SketchPoint>? points,
    int? colorArgb,
    double? width,
    double? opacity,
    bool? isHighlighter,
    String? layerId,
    bool? locked,
    bool? visible,
  }) {
    return SketchStroke(
      id: id,
      points: points ?? this.points,
      colorArgb: colorArgb ?? this.colorArgb,
      width: width ?? this.width,
      opacity: opacity ?? this.opacity,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      layerId: layerId ?? this.layerId,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'colorArgb': colorArgb,
        'width': width,
        'opacity': opacity,
        'isHighlighter': isHighlighter,
        'layerId': layerId,
        'locked': locked,
        'visible': visible,
      };

  factory SketchStroke.fromJson(Map<String, dynamic> json) => SketchStroke(
        id: json['id'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) => SketchPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        colorArgb: json['colorArgb'] as int,
        width: (json['width'] as num).toDouble(),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        isHighlighter: json['isHighlighter'] as bool? ?? false,
        layerId: json['layerId'] as String? ?? 'drawing',
        locked: json['locked'] as bool? ?? false,
        visible: json['visible'] as bool? ?? true,
      );
}

class SketchShape {
  const SketchShape({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.strokeColorArgb = 0xFF000000,
    this.fillColorArgb,
    this.strokeWidth = 2,
    this.opacity = 1,
    this.layerId = 'shapes',
    this.locked = false,
    this.visible = true,
  });

  final String id;
  final SketchShapeKind kind;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int strokeColorArgb;
  final int? fillColorArgb;
  final double strokeWidth;
  final double opacity;
  final String layerId;
  final bool locked;
  final bool visible;

  Rect boundsRect(Size size) => Rect.fromLTWH(
        x * size.width,
        y * size.height,
        width * size.width,
        height * size.height,
      );

  SketchShape copyWith({
    SketchShapeKind? kind,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? strokeColorArgb,
    int? fillColorArgb,
    bool clearFill = false,
    double? strokeWidth,
    double? opacity,
    String? layerId,
    bool? locked,
    bool? visible,
  }) {
    return SketchShape(
      id: id,
      kind: kind ?? this.kind,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      strokeColorArgb: strokeColorArgb ?? this.strokeColorArgb,
      fillColorArgb: clearFill ? null : (fillColorArgb ?? this.fillColorArgb),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'strokeColorArgb': strokeColorArgb,
        'fillColorArgb': fillColorArgb,
        'strokeWidth': strokeWidth,
        'opacity': opacity,
        'layerId': layerId,
        'locked': locked,
        'visible': visible,
      };

  factory SketchShape.fromJson(Map<String, dynamic> json) => SketchShape(
        id: json['id'] as String,
        kind: SketchShapeKind.values.byName(json['kind'] as String),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        strokeColorArgb: json['strokeColorArgb'] as int? ?? 0xFF000000,
        fillColorArgb: json['fillColorArgb'] as int?,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        layerId: json['layerId'] as String? ?? 'shapes',
        locked: json['locked'] as bool? ?? false,
        visible: json['visible'] as bool? ?? true,
      );
}

class SketchTextAnnotation {
  const SketchTextAnnotation({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    this.fontSize = 16,
    this.colorArgb = 0xFF000000,
    this.backgroundColorArgb,
    this.rotation = 0,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.alignment = TextAlign.left,
    this.opacity = 1,
    this.layerId = 'text',
    this.locked = false,
    this.visible = true,
  });

  final String id;
  final double x;
  final double y;
  final String text;
  final double fontSize;
  final int colorArgb;
  final int? backgroundColorArgb;
  final double rotation;
  final bool bold;
  final bool italic;
  final bool underline;
  final TextAlign alignment;
  final double opacity;
  final String layerId;
  final bool locked;
  final bool visible;

  SketchTextAnnotation copyWith({
    double? x,
    double? y,
    String? text,
    double? fontSize,
    int? colorArgb,
    int? backgroundColorArgb,
    bool clearBackground = false,
    double? rotation,
    bool? bold,
    bool? italic,
    bool? underline,
    TextAlign? alignment,
    double? opacity,
    String? layerId,
    bool? locked,
    bool? visible,
  }) {
    return SketchTextAnnotation(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      colorArgb: colorArgb ?? this.colorArgb,
      backgroundColorArgb:
          clearBackground ? null : (backgroundColorArgb ?? this.backgroundColorArgb),
      rotation: rotation ?? this.rotation,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      alignment: alignment ?? this.alignment,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'text': text,
        'fontSize': fontSize,
        'colorArgb': colorArgb,
        'backgroundColorArgb': backgroundColorArgb,
        'rotation': rotation,
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'alignment': alignment.name,
        'opacity': opacity,
        'layerId': layerId,
        'locked': locked,
        'visible': visible,
      };

  factory SketchTextAnnotation.fromJson(Map<String, dynamic> json) => SketchTextAnnotation(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        text: json['text'] as String? ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
        colorArgb: json['colorArgb'] as int? ?? 0xFF000000,
        backgroundColorArgb: json['backgroundColorArgb'] as int?,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        underline: json['underline'] as bool? ?? false,
        alignment: TextAlign.values.byName(json['alignment'] as String? ?? 'left'),
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        layerId: json['layerId'] as String? ?? 'text',
        locked: json['locked'] as bool? ?? false,
        visible: json['visible'] as bool? ?? true,
      );
}

class SketchImageAnnotation {
  const SketchImageAnnotation({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.storagePath,
    this.rotation = 0,
    this.opacity = 1,
    this.flipX = false,
    this.layerId = 'images',
    this.locked = false,
    this.visible = true,
  });

  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String storagePath;
  final double rotation;
  final double opacity;
  final bool flipX;
  final String layerId;
  final bool locked;
  final bool visible;

  SketchImageAnnotation copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? storagePath,
    double? rotation,
    double? opacity,
    bool? flipX,
    String? layerId,
    bool? locked,
    bool? visible,
  }) {
    return SketchImageAnnotation(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      storagePath: storagePath ?? this.storagePath,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      flipX: flipX ?? this.flipX,
      layerId: layerId ?? this.layerId,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'storagePath': storagePath,
        'rotation': rotation,
        'opacity': opacity,
        'flipX': flipX,
        'layerId': layerId,
        'locked': locked,
        'visible': visible,
      };

  factory SketchImageAnnotation.fromJson(Map<String, dynamic> json) =>
      SketchImageAnnotation(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        storagePath: json['storagePath'] as String,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        flipX: json['flipX'] as bool? ?? false,
        layerId: json['layerId'] as String? ?? 'images',
        locked: json['locked'] as bool? ?? false,
        visible: json['visible'] as bool? ?? true,
      );
}

class SketchBlueprintTransform {
  const SketchBlueprintTransform({
    this.x = 0,
    this.y = 0,
    this.scale = 1,
    this.rotation = 0,
    this.cropRect,
  });

  final double x;
  final double y;
  final double scale;
  final double rotation;
  final Rect? cropRect;

  SketchBlueprintTransform copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    Rect? cropRect,
    bool clearCrop = false,
  }) {
    return SketchBlueprintTransform(
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      cropRect: clearCrop ? null : (cropRect ?? this.cropRect),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        if (cropRect != null)
          'cropRect': {
            'l': cropRect!.left,
            't': cropRect!.top,
            'r': cropRect!.right,
            'b': cropRect!.bottom,
          },
      };

  factory SketchBlueprintTransform.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SketchBlueprintTransform();
    Rect? crop;
    final cropJson = json['cropRect'] as Map<String, dynamic>?;
    if (cropJson != null) {
      crop = Rect.fromLTRB(
        (cropJson['l'] as num).toDouble(),
        (cropJson['t'] as num).toDouble(),
        (cropJson['r'] as num).toDouble(),
        (cropJson['b'] as num).toDouble(),
      );
    }
    return SketchBlueprintTransform(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      cropRect: crop,
    );
  }
}

class SketchToolSettings {
  const SketchToolSettings({
    this.activeTool = SketchTool.pen,
    this.brushSize = SketchBrushSize.medium,
    this.penColorArgb = 0xFF1A1A1A,
    this.highlighterColorArgb = 0xFFFFEB3B,
    this.shapeKind = SketchShapeKind.rectangle,
    this.eraserMode = EraserMode.stroke,
    this.eraserSize = 12,
    this.strokeColorArgb = 0xFF1565C0,
    this.fillColorArgb,
    this.textColorArgb = 0xFF1A1A1A,
    this.textFontSize = 16,
  });

  final SketchTool activeTool;
  final SketchBrushSize brushSize;
  final int penColorArgb;
  final int highlighterColorArgb;
  final SketchShapeKind shapeKind;
  final EraserMode eraserMode;
  final double eraserSize;
  final int strokeColorArgb;
  final int? fillColorArgb;
  final int textColorArgb;
  final double textFontSize;

  SketchToolSettings copyWith({
    SketchTool? activeTool,
    SketchBrushSize? brushSize,
    int? penColorArgb,
    int? highlighterColorArgb,
    SketchShapeKind? shapeKind,
    EraserMode? eraserMode,
    double? eraserSize,
    int? strokeColorArgb,
    int? fillColorArgb,
    bool clearFill = false,
    int? textColorArgb,
    double? textFontSize,
  }) {
    return SketchToolSettings(
      activeTool: activeTool ?? this.activeTool,
      brushSize: brushSize ?? this.brushSize,
      penColorArgb: penColorArgb ?? this.penColorArgb,
      highlighterColorArgb: highlighterColorArgb ?? this.highlighterColorArgb,
      shapeKind: shapeKind ?? this.shapeKind,
      eraserMode: eraserMode ?? this.eraserMode,
      eraserSize: eraserSize ?? this.eraserSize,
      strokeColorArgb: strokeColorArgb ?? this.strokeColorArgb,
      fillColorArgb: clearFill ? null : (fillColorArgb ?? this.fillColorArgb),
      textColorArgb: textColorArgb ?? this.textColorArgb,
      textFontSize: textFontSize ?? this.textFontSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeTool': activeTool.name,
        'brushSize': brushSize.name,
        'penColorArgb': penColorArgb,
        'highlighterColorArgb': highlighterColorArgb,
        'shapeKind': shapeKind.name,
        'eraserMode': eraserMode.name,
        'eraserSize': eraserSize,
        'strokeColorArgb': strokeColorArgb,
        'fillColorArgb': fillColorArgb,
        'textColorArgb': textColorArgb,
        'textFontSize': textFontSize,
      };

  factory SketchToolSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SketchToolSettings();
    return SketchToolSettings(
      activeTool: SketchTool.values.byName(json['activeTool'] as String? ?? 'pen'),
      brushSize:
          SketchBrushSize.values.byName(json['brushSize'] as String? ?? 'medium'),
      penColorArgb: json['penColorArgb'] as int? ?? 0xFF1A1A1A,
      highlighterColorArgb: json['highlighterColorArgb'] as int? ?? 0xFFFFEB3B,
      shapeKind:
          SketchShapeKind.values.byName(json['shapeKind'] as String? ?? 'rectangle'),
      eraserMode: EraserMode.values.byName(json['eraserMode'] as String? ?? 'stroke'),
      eraserSize: (json['eraserSize'] as num?)?.toDouble() ?? 12,
      strokeColorArgb: json['strokeColorArgb'] as int? ?? 0xFF1565C0,
      fillColorArgb: json['fillColorArgb'] as int?,
      textColorArgb: json['textColorArgb'] as int? ?? 0xFF1A1A1A,
      textFontSize: (json['textFontSize'] as num?)?.toDouble() ?? 16,
    );
  }
}

class SketchDocument {
  const SketchDocument({
    this.strokes = const [],
    this.shapes = const [],
    this.texts = const [],
    this.images = const [],
    this.blueprintTransform = const SketchBlueprintTransform(),
    this.toolSettings = const SketchToolSettings(),
    this.includeInPdfExport = false,
    this.canvasWidth = 1,
    this.canvasHeight = 1,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
    this.selectedObjectId,
  });

  final List<SketchStroke> strokes;
  final List<SketchShape> shapes;
  final List<SketchTextAnnotation> texts;
  final List<SketchImageAnnotation> images;
  final SketchBlueprintTransform blueprintTransform;
  final SketchToolSettings toolSettings;
  final bool includeInPdfExport;
  final double canvasWidth;
  final double canvasHeight;
  final double zoom;
  final double panX;
  final double panY;
  final String? selectedObjectId;

  bool get isEmpty =>
      strokes.isEmpty && shapes.isEmpty && texts.isEmpty && images.isEmpty;

  SketchDocument copyWith({
    List<SketchStroke>? strokes,
    List<SketchShape>? shapes,
    List<SketchTextAnnotation>? texts,
    List<SketchImageAnnotation>? images,
    SketchBlueprintTransform? blueprintTransform,
    SketchToolSettings? toolSettings,
    bool? includeInPdfExport,
    double? canvasWidth,
    double? canvasHeight,
    double? zoom,
    double? panX,
    double? panY,
    String? selectedObjectId,
    bool clearSelection = false,
  }) {
    return SketchDocument(
      strokes: strokes ?? this.strokes,
      shapes: shapes ?? this.shapes,
      texts: texts ?? this.texts,
      images: images ?? this.images,
      blueprintTransform: blueprintTransform ?? this.blueprintTransform,
      toolSettings: toolSettings ?? this.toolSettings,
      includeInPdfExport: includeInPdfExport ?? this.includeInPdfExport,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      selectedObjectId: clearSelection ? null : (selectedObjectId ?? this.selectedObjectId),
    );
  }

  Map<String, dynamic> toJson() => {
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'shapes': shapes.map((s) => s.toJson()).toList(),
        'texts': texts.map((t) => t.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
        'blueprintTransform': blueprintTransform.toJson(),
        'toolSettings': toolSettings.toJson(),
        'includeInPdfExport': includeInPdfExport,
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
        'selectedObjectId': selectedObjectId,
      };

  factory SketchDocument.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SketchDocument();
    return SketchDocument(
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((e) => SketchStroke.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      shapes: (json['shapes'] as List<dynamic>?)
              ?.map((e) => SketchShape.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      texts: (json['texts'] as List<dynamic>?)
              ?.map((e) => SketchTextAnnotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => SketchImageAnnotation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      blueprintTransform:
          SketchBlueprintTransform.fromJson(json['blueprintTransform'] as Map<String, dynamic>?),
      toolSettings: SketchToolSettings.fromJson(json['toolSettings'] as Map<String, dynamic>?),
      includeInPdfExport: json['includeInPdfExport'] as bool? ?? false,
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 1,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 1,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1,
      panX: (json['panX'] as num?)?.toDouble() ?? 0,
      panY: (json['panY'] as num?)?.toDouble() ?? 0,
      selectedObjectId: json['selectedObjectId'] as String?,
    );
  }
}

int colorToArgb(Color color) => color.toARGB32();

Color colorFromArgb(int argb) => Color(argb);
