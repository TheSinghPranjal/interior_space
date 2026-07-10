class WalkthroughSettings {
  const WalkthroughSettings({this.eyeHeightFt = 5});

  static const int minEyeHeightFt = 2;
  static const int maxEyeHeightFt = 8;
  static const int defaultEyeHeightFt = 5;

  static const List<int> eyeHeightOptions = [2, 3, 4, 5, 6, 7, 8];

  final int eyeHeightFt;

  int get clampedEyeHeightFt =>
      eyeHeightFt.clamp(minEyeHeightFt, maxEyeHeightFt);

  WalkthroughSettings copyWith({int? eyeHeightFt}) {
    return WalkthroughSettings(
      eyeHeightFt: eyeHeightFt ?? this.eyeHeightFt,
    );
  }

  Map<String, dynamic> toJson() => {
        'eyeHeightFt': clampedEyeHeightFt,
      };

  factory WalkthroughSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['eyeHeightFt'];
    final height = raw is int
        ? raw
        : int.tryParse(raw?.toString() ?? '') ?? defaultEyeHeightFt;
    return WalkthroughSettings(eyeHeightFt: height);
  }
}
