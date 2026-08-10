import 'package:flutter_test/flutter_test.dart';
import 'package:itmain_app/main.dart';

void main() {
  testWidgets('Itmain app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ItmainApp());
    expect(find.text('اطمئن'), findsOneWidget);
  });
}
