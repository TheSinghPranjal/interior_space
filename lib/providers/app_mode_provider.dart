import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSpaceMode {
  interior,
  apartment,
}

extension AppSpaceModeLabel on AppSpaceMode {
  String get title => switch (this) {
        AppSpaceMode.interior => 'Interior Space',
        AppSpaceMode.apartment => 'Apartment Space',
      };
}

final appSpaceModeProvider = StateProvider<AppSpaceMode>((ref) {
  return AppSpaceMode.interior;
});
