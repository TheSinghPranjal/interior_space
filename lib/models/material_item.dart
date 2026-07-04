enum MaterialCategory { floor, wall, ceiling, furniture }

class MaterialItem {
  final String id;
  final String name;
  final MaterialCategory category;
  final String subCategory;
  final String? assetPath;
  final String? filePath;
  final String? colorHex;
  final bool isUserAdded;
  final DateTime createdAt;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    this.assetPath,
    this.filePath,
    this.colorHex,
    this.isUserAdded = false,
    required this.createdAt,
  });

  bool get isColor => colorHex != null && filePath == null && assetPath == null;
  bool get hasImage => assetPath != null || filePath != null;

  MaterialItem copyWith({
    String? id,
    String? name,
    MaterialCategory? category,
    String? subCategory,
    String? assetPath,
    String? filePath,
    String? colorHex,
    bool? isUserAdded,
    DateTime? createdAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      colorHex: colorHex ?? this.colorHex,
      isUserAdded: isUserAdded ?? this.isUserAdded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'subCategory': subCategory,
        'assetPath': assetPath,
        'filePath': filePath,
        'colorHex': colorHex,
        'isUserAdded': isUserAdded,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: MaterialCategory.values.firstWhere(
          (e) => e.name == json['category'],
        ),
        subCategory: json['subCategory'] as String,
        assetPath: json['assetPath'] as String?,
        filePath: json['filePath'] as String?,
        colorHex: json['colorHex'] as String?,
        isUserAdded: json['isUserAdded'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
