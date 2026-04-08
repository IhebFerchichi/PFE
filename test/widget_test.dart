import 'package:flutter_test/flutter_test.dart';

import 'package:battery_pack_app/src/app.dart';

void main() {
  testWidgets('shows login shell by default', (tester) async {
    await tester.pumpWidget(BatteryPackApp());

    expect(find.text('Battery Pack Mobile'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
