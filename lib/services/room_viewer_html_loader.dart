import 'package:flutter/services.dart';

/// Loads the pre-bundled 3D viewer HTML (Three.js + OrbitControls + renderer inlined).
class RoomViewerHtmlLoader {
  static const _bundlePath = 'assets/three/viewer.html';

  static Future<String> load() async {
    return rootBundle.loadString(_bundlePath);
  }
}
