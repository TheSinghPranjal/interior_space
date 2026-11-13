import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interior_space/core/theme/app_theme.dart';
import 'package:interior_space/screens/splash_screen.dart';
import 'package:interior_space/widgets/branding/app_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSplash(
    WidgetTester tester, {
    required Size size,
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
  }

  Future<void> finishSplash(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 2000));
  }

  void expectByline(WidgetTester tester) {
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(find.text('Abode'), findsOneWidget);
    expect(find.text('Loading your workspace…'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);

    final screen = tester.getSize(find.byType(SplashScreen));
    final logo = tester.getRect(find.byType(AppLogo));
    final name = tester.getRect(find.text('The Lazy Bear Club'));
    final byWord = tester.getRect(find.text('by'));
    final icon = tester.getRect(find.byType(Image));
    final groupLeft = [icon.left, byWord.left, name.left].reduce((a, b) => a < b ? a : b);
    final groupRight = [icon.right, byWord.right, name.right].reduce((a, b) => a > b ? a : b);

    final loading = tester.getRect(find.text('Loading your workspace…'));
    expect(name.top, greaterThan(loading.bottom));
    expect(byWord.bottom, lessThanOrEqualTo(name.top + 1));
    expect(name.bottom, greaterThan(screen.height * 0.7));
    expect(logo.center.dx, closeTo(screen.width / 2, 2));
    expect((groupLeft + groupRight) / 2, closeTo(screen.width / 2, 4));
  }

  testWidgets('splash byline sits under the mark on a phone', (tester) async {
    await pumpSplash(tester, size: const Size(390, 844));
    expectByline(tester);
    final screen = tester.getSize(find.byType(SplashScreen));
    final logo = tester.getRect(find.byType(AppLogo));
    final loading = tester.getRect(find.text('Loading your workspace…'));
    final columnCenter = (logo.top + loading.bottom) / 2;
    expect(columnCenter, closeTo(screen.height / 2, 12));
    await finishSplash(tester);
  });

  testWidgets('splash byline fits a small phone and landscape', (tester) async {
    await pumpSplash(tester, size: const Size(320, 568));
    expectByline(tester);
    await finishSplash(tester);

    await pumpSplash(tester, size: const Size(740, 360));
    expectByline(tester);
    await finishSplash(tester);
  });

  testWidgets('splash byline fits a tablet and large text', (tester) async {
    await pumpSplash(tester, size: const Size(834, 1194));
    expectByline(tester);
    await finishSplash(tester);

    await pumpSplash(
      tester,
      size: const Size(320, 568),
      textScale: 2,
    );
    expectByline(tester);
    await finishSplash(tester);
  });

  testWidgets('splash byline keeps dark ink in a dark theme', (tester) async {
    await pumpSplash(
      tester,
      size: const Size(390, 844),
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    );
    expectByline(tester);

    final byStyle = tester.widget<Text>(find.text('by')).style;
    final nameStyle = tester.widget<Text>(find.text('The Lazy Bear Club')).style;
    expect(byStyle?.color, AppTheme.textSecondary);
    expect(nameStyle?.color, AppTheme.textPrimary);
    await finishSplash(tester);
  });
}
