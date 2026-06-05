import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:interior_space/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InteriorSpaceApp()));
    await tester.pumpAndSettle();

    expect(find.text('Interior Space'), findsOneWidget);
    expect(find.text('My Room'), findsWidgets);
    expect(find.text('Room Dimensions'), findsOneWidget);
  });
}
