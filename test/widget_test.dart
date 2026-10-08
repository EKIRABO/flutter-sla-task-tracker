import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sla_task_tracker/main.dart';

void main() {
  testWidgets('sign-in requires a name', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(find.text('Hi, Esther'), findsNothing);
  });

  testWidgets('sign-in opens the dashboard for the entered user',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextFormField), 'Esther');
    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Esther'), findsOneWidget);
    expect(find.text('SLA overview'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Needs attention'),
      300,
    );
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Design Login Screen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fix Navigation Bug'),
      200,
    );
    expect(find.text('Fix Navigation Bug'), findsOneWidget);
  });

  testWidgets('dashboard task destination opens the task list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField), 'Esther');
    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Set Up Database'), findsOneWidget);
  });
}
