class AppNavSettings {
  const AppNavSettings({
    this.showSketchTab = true,
    this.showAiAssistTab = true,
  });

  final bool showSketchTab;
  final bool showAiAssistTab;

  AppNavSettings copyWith({
    bool? showSketchTab,
    bool? showAiAssistTab,
  }) {
    return AppNavSettings(
      showSketchTab: showSketchTab ?? this.showSketchTab,
      showAiAssistTab: showAiAssistTab ?? this.showAiAssistTab,
    );
  }

  Map<String, dynamic> toJson() => {
        'showSketchTab': showSketchTab,
        'showAiAssistTab': showAiAssistTab,
      };

  factory AppNavSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppNavSettings();
    return AppNavSettings(
      showSketchTab: json['showSketchTab'] as bool? ?? true,
      showAiAssistTab: json['showAiAssistTab'] as bool? ?? true,
    );
  }
}
