import 'package:flutter_test/flutter_test.dart';

import 'package:lectura/main.dart';

void main() {
  testWidgets('App boots and shows the CloudRead splash', (tester) async {
    await tester.pumpWidget(const CloudReadApp());
    await tester.pump();

    expect(find.text('CloudRead'), findsOneWidget);
    expect(find.text('Your digital library'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
  });
}
