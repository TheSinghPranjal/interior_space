enum SketchTool {
  pen,
  highlighter,
  eraser,
  shapes,
  text,
  image,
  crop,
  rotate,
  select,
}

enum SketchBrushSize {
  verySmall,
  small,
  medium,
  large,
  extraLarge,
}

extension SketchBrushSizeExt on SketchBrushSize {
  double get width => switch (this) {
        SketchBrushSize.verySmall => 1.5,
        SketchBrushSize.small => 3.0,
        SketchBrushSize.medium => 6.0,
        SketchBrushSize.large => 10.0,
        SketchBrushSize.extraLarge => 16.0,
      };

  String get label => switch (this) {
        SketchBrushSize.verySmall => 'Very Small',
        SketchBrushSize.small => 'Small',
        SketchBrushSize.medium => 'Medium',
        SketchBrushSize.large => 'Large',
        SketchBrushSize.extraLarge => 'Extra Large',
      };
}

enum SketchShapeKind {
  rectangle,
  circle,
  ellipse,
  line,
  arrow,
  doubleArrow,
  triangle,
  speechBubble,
}

enum EraserMode {
  stroke,
  object,
}

enum SketchLayerType {
  blueprint,
  drawing,
  shapes,
  text,
  images,
}
