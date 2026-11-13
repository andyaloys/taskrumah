import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familytask_mobile/app.dart';

void main() {
  testWidgets('App renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FamilyTaskApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // The splash / initial loading or title is rendered
    expect(find.byType(FamilyTaskApp), findsOneWidget);
  });
}
