import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExtraBiteApp(),
      ),
    );
    expect(find.byType(ExtraBiteApp), findsOneWidget);
  });
}
