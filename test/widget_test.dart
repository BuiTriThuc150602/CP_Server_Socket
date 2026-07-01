import 'package:flutter_test/flutter_test.dart';
import 'package:socket_server/app/app.dart';

void main() {
  testWidgets('opens module shell', (tester) async {
    await tester.pumpWidget(const SocketTestingToolsApp());

    expect(find.text('Socket Testing Tools'), findsOneWidget);
    expect(find.text('CarParking Device Gateway Simulator'), findsOneWidget);
    expect(find.text('TCP Socket Lab'), findsOneWidget);
  });
}
