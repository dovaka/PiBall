import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piball/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('primary button cycles Start -> Stop -> Start', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Start'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Stop'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Start'), findsOneWidget);

    expect(find.text('Winds aloft'), findsNothing);
  });
}
