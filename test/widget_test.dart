import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('LumoCustomerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LumoCustomerApp());
    expect(find.text('LUMO Safety App'), findsOneWidget);
  });
}
