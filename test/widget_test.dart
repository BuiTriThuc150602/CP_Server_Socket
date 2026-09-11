import 'package:flutter_test/flutter_test.dart';
import 'package:fluxlab/app/app.dart';

void main() {
  testWidgets('opens module shell', (tester) async {
    await tester.pumpWidget(const FluxLabApp());

    expect(find.text('FluxLab'), findsOneWidget);
    expect(find.text('CarParking Device Gateway Simulator'), findsOneWidget);
    expect(find.text('TCP Socket Lab'), findsOneWidget);
  });
}
