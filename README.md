# Interior Space — 3D Room Designer & Visualizer

A cross-platform Flutter application for designing and visualizing rooms in real-time 3D.

## Features

- **Room Setup** — Configure dimensions (default 16×8×10 ft) with validation
- **Blueprint View** — 2D floor plan for placing beds, wardrobes, cupboards (drag to reposition)
- **3D Model View** — Realistic WebGL rendering via Three.js with exact placement & dimensions
- **Walls** — Per-wall color, texture (brick, marble, wood…), or custom wallpaper upload
- **Flooring** — Colors, tile patterns, materials (marble, granite, ceramic…), texture upload
- **Ceiling** — Colors, textures, false ceiling types (cove, tray, floating…)
- **Doors & Windows** — Multiple openings with wall cutouts in 3D
- **Cupboards & Furniture** — Place in blueprint, render in 3D
- **Lighting** — Ceiling, spot, LED strip, chandelier, wall lights with warmth settings
- **Camera Modes** — Orbit, walk, first-person, top, front, side, isometric
- **Export** — Screenshot, PDF design sheet, shareable project file
- **AI-Ready** — Architecture supports future AI design suggestions

## Architecture

```
lib/
├── core/           # Theme, constants, utilities
├── models/         # Room design data models (JSON serializable)
├── providers/      # Riverpod state management
├── services/       # Storage, textures, export, scene builder
├── screens/        # Home, Blueprint, 3D Preview
└── widgets/        # Editors, blueprint canvas, 3D viewer

assets/three/       # Three.js room renderer (WebGL)
  viewer.html       # Self-contained bundle (Three.js + OrbitControls + renderer)
scripts/bundle_viewer.sh  # Rebuild viewer.html after editing JS files
```

**3D Engine:** Flutter + Three.js via `flutter_inappwebview` (WebGL-based renderer). All JS is bundled offline into `viewer.html` — no CDN required.

**State:** Riverpod with auto-save to SharedPreferences

## Getting Started

```bash
flutter pub get
flutter run
```

### Requirements

- Flutter 3.11+
- Internet connection (Three.js loaded from CDN on first 3D view)
- iOS/Android device or emulator with WebView support

## Blueprint → 3D Workflow

1. Design room dimensions and surfaces in editor tabs
2. Open **Blueprint** to place furniture and cupboards on the floor plan
3. Drag items to reposition; adjust sizes in Furniture/Cupboards tabs
4. Tap **Show 3D Model** for the realistic view with lighting, textures, and dimensions

## Project JSON Schema

```json
{
  "room": { "width": 16, "length": 8, "height": 10 },
  "walls": [],
  "floor": {},
  "ceiling": {},
  "doors": [],
  "windows": [],
  "cupboards": [],
  "lights": [],
  "furniture": []
}
```
