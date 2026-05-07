import 'package:flutter_test/flutter_test.dart';

import 'package:incident_reporter/main.dart';

void main() {
  testWidgets('shows login screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Incident Reporter'), findsOneWidget);
    expect(find.text('Authorize Access'), findsOneWidget);
    expect(find.text('Sign in with SSO'), findsOneWidget);
  });
}
