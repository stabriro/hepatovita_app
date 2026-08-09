import 'package:flutter_test/flutter_test.dart';
import 'package:hepatovita_app/main.dart';

void main() {
  testWidgets('HepatoVita app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HepatoVitaApp());
    expect(find.text('HepatoVita'), findsOneWidget);
  });
}
