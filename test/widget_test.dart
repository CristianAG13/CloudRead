// Basic smoke test for the CloudRead app shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:lectura/main.dart';

void main() {
  testWidgets('App boots and shows the CloudRead home header', (tester) async {
    await tester.pumpWidget(const CloudReadApp());
    await tester.pump();

    expect(find.text('CloudRead'), findsOneWidget);
  });
}
