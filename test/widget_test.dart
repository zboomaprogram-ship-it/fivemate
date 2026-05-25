import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:_5amat/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build our app wrapped in ProviderScope and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: MainApp(),
        ),
      );

      // Verify that the app widget structure starts successfully
      expect(find.byType(ProviderScope), findsOneWidget);
      expect(find.byType(MainApp), findsOneWidget);
    });
  });
}
