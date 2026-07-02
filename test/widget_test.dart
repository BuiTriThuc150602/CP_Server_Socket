import 'package:flutter_test/flutter_test.dart';
import 'package:testdeck/app/app.dart';

void main() {
  testWidgets('opens module shell', (tester) async {
    await tester.pumpWidget(const TestDeckApp());

    expect(find.text('TestDeck'), findsOneWidget);
    expect(find.text('CarParking Device Gateway Simulator'), findsOneWidget);
    expect(find.text('TCP Socket Lab'), findsOneWidget);
  });
}
