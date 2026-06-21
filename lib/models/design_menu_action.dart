import 'package:flutter/material.dart';

enum DesignMenuAction {
  roomSetup,
  walls,
  flooring,
  ceiling,
  doors,
  windows,
  cupboards,
  furniture,
  lighting,
  blueprint,
}

extension DesignMenuActionInfo on DesignMenuAction {
  String get label => switch (this) {
        DesignMenuAction.roomSetup => 'Room Setup',
        DesignMenuAction.walls => 'Walls',
        DesignMenuAction.flooring => 'Flooring',
        DesignMenuAction.ceiling => 'Ceiling',
        DesignMenuAction.doors => 'Doors',
        DesignMenuAction.windows => 'Windows, Ac & Curtains',
        DesignMenuAction.cupboards => 'Cupboards',
        DesignMenuAction.furniture => 'Furniture',
        DesignMenuAction.lighting => 'Lighting',
        DesignMenuAction.blueprint => 'Blueprint',
      };

  IconData get icon => switch (this) {
        DesignMenuAction.roomSetup => Icons.square_foot,
        DesignMenuAction.walls => Icons.wallpaper,
        DesignMenuAction.flooring => Icons.grid_on,
        DesignMenuAction.ceiling => Icons.roofing,
        DesignMenuAction.doors => Icons.door_front_door,
        DesignMenuAction.windows => Icons.window,
        DesignMenuAction.cupboards => Icons.kitchen,
        DesignMenuAction.furniture => Icons.chair,
        DesignMenuAction.lighting => Icons.lightbulb,
        DesignMenuAction.blueprint => Icons.architecture,
      };
}

enum MainNavTab { room, blueprint, preview3d, aiAssist }
