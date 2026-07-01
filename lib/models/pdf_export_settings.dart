class PdfExportSettings {
  const PdfExportSettings({
    this.include3dPreview = true,
    this.includeFrontView = true,
    this.includeTopView = true,
  });

  final bool include3dPreview;
  final bool includeFrontView;
  final bool includeTopView;

  bool get shouldCapture3d =>
      include3dPreview && (includeFrontView || includeTopView);

  PdfExportSettings copyWith({
    bool? include3dPreview,
    bool? includeFrontView,
    bool? includeTopView,
  }) {
    return PdfExportSettings(
      include3dPreview: include3dPreview ?? this.include3dPreview,
      includeFrontView: includeFrontView ?? this.includeFrontView,
      includeTopView: includeTopView ?? this.includeTopView,
    );
  }

  Map<String, dynamic> toJson() => {
        'include3dPreview': include3dPreview,
        'includeFrontView': includeFrontView,
        'includeTopView': includeTopView,
      };

  factory PdfExportSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PdfExportSettings();
    return PdfExportSettings(
      include3dPreview: json['include3dPreview'] as bool? ?? true,
      includeFrontView: json['includeFrontView'] as bool? ?? true,
      includeTopView: json['includeTopView'] as bool? ?? true,
    );
  }
}
