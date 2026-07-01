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

class ApartmentPdf3DCaptureResult {
  const ApartmentPdf3DCaptureResult({
    this.roomImages = const {},
    this.apartmentTopView,
    this.apartmentFrontView,
  });

  final Map<int, Room3DExportImages> roomImages;
  final Uint8List? apartmentTopView;
  final Uint8List? apartmentFrontView;
}

/// Which rooms and apartment overview to capture for PDF 3D previews.
enum PdfExportCaptureScope {
  /// Active room only.
  singleRoom,

  /// Every room in the active apartment (no apartment overview).
  allRooms,

  /// Full apartment overview plus every room in the active apartment.
  apartment,
}
