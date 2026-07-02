import 'package:flutter/material.dart';

enum DesignMenuAction {
  roomSetup,
  walls,
  flooring,
  ceiling,
  stairs,
  doors,
  windows,
  furniture,
  lighting,
  blueprint,
}

extension DesignMenuActionInfo on DesignMenuAction {
  String label({bool premiumFurniture = false}) => switch (this) {
        DesignMenuAction.roomSetup => 'Room Setup',
        DesignMenuAction.walls => 'Walls',
        DesignMenuAction.flooring => 'Flooring',
        DesignMenuAction.ceiling => 'Ceiling',
        DesignMenuAction.stairs => 'Stairs',
        DesignMenuAction.doors => 'Doors',
        DesignMenuAction.windows => 'Windows, Ac & Curtains',
        DesignMenuAction.furniture =>
          premiumFurniture ? 'Furniture & Objects' : 'Furniture',
        DesignMenuAction.lighting => 'Lighting',
        DesignMenuAction.blueprint => 'Blueprint',
      };

  IconData get icon => switch (this) {
        DesignMenuAction.roomSetup => Icons.square_foot,
        DesignMenuAction.walls => Icons.wallpaper,
        DesignMenuAction.flooring => Icons.grid_on,
        DesignMenuAction.ceiling => Icons.roofing,
        DesignMenuAction.stairs => Icons.stairs_outlined,
        DesignMenuAction.doors => Icons.door_front_door,
        DesignMenuAction.windows => Icons.window,
        DesignMenuAction.furniture => Icons.chair,
        DesignMenuAction.lighting => Icons.lightbulb,
        DesignMenuAction.blueprint => Icons.architecture,
      };
}

enum MainNavTab { room, blueprint, sketch, preview3d, aiAssist, settings }
