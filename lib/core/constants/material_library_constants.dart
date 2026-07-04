import 'package:interior_space/models/material_item.dart';


class MaterialLibraryConstants {
  static const subLabels = {
    'wood': 'Wood',
    'marble': 'Marble',
    'granite': 'Granite',
    'tiles': 'Tiles',
    'concrete': 'Concrete',
    'brick': 'Brick',
    'paint': 'Paint',
    'wallpaper': 'Wallpaper',
    'stone': 'Stone',
    'panels': 'Panels',
    '3dPanels': '3D Panel',
    'gypsum': 'Gypsum',
    'pop': 'POP',
    'falseCeiling': 'False Ceiling',
    'ledCove': 'LED Cove',
    'sofas': 'Sofas',
    'tables': 'Tables',
    'chairs': 'Chairs',
    'beds': 'Beds',
    'storage': 'Storage',
    'decor': 'Decor',
    'custom': 'Custom',
  };

  static const subsByCategory = {
    MaterialCategory.floor: {
      'all': 'All',
      'wood': 'Wood',
      'marble': 'Marble',
      'granite': 'Granite',
      'tiles': 'Tiles',
      'concrete': 'Concrete',
      'brick': 'Brick',
    },
    MaterialCategory.wall: {
      'all': 'All',
      'paint': 'Paint',
      'wallpaper': 'Wallpaper',
      'stone': 'Stone',
      'wood': 'Wood',
      'panels': 'Panels',
      '3dPanels': '3D Panel',
    },
    MaterialCategory.ceiling: {
      'all': 'All',
      'gypsum': 'Gypsum',
      'pop': 'POP',
      'wood': 'Wood',
      'falseCeiling': 'False Ceiling',
      'ledCove': 'LED Cove',
    },
    MaterialCategory.furniture: {
      'all': 'All',
      'sofas': 'Sofas',
      'tables': 'Tables',
      'chairs': 'Chairs',
      'beds': 'Beds',
      'storage': 'Storage',
      'decor': 'Decor',
    },
  };

  static const subCategoriesForAdd = {
    MaterialCategory.floor: ['wood', 'marble', 'granite', 'tiles', 'concrete', 'brick'],
    MaterialCategory.wall: ['paint', 'wallpaper', 'stone', 'wood', 'panels', '3dPanels'],
    MaterialCategory.ceiling: ['gypsum', 'pop', 'wood', 'falseCeiling', 'ledCove'],
    MaterialCategory.furniture: ['sofas', 'tables', 'chairs', 'beds', 'storage', 'decor'],
  };

  static String categoryTitle(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.floor:
        return 'Floor Library';
      case MaterialCategory.wall:
        return 'Wall Library';
      case MaterialCategory.ceiling:
        return 'Ceiling Library';
      case MaterialCategory.furniture:
        return 'Furniture Library';
    }
  }

  static String categoryShortLabel(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.floor:
        return 'Floor';
      case MaterialCategory.wall:
        return 'Wall';
      case MaterialCategory.ceiling:
        return 'Ceiling';
      case MaterialCategory.furniture:
        return 'Furniture';
    }
  }

  static String subLabel(String sub) => subLabels[sub] ?? sub;
}
