import 'dart:typed_data';

class Room3DExportImages {
  const Room3DExportImages({
    this.front,
    this.top,
  });

  final Uint8List? front;
  final Uint8List? top;

  bool get hasAny => front != null || top != null;
}
