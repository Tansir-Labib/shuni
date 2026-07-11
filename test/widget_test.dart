import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuni/app.dart';

void main() {
  testWidgets('ShuniApp mounts successfully', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ShuniApp(),
      ),
    );

    // Verify that the root ShuniApp widget exists in the tree.
    expect(find.byType(ShuniApp), findsOneWidget);
  });
}
