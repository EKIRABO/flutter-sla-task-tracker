import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sla_task_tracker/database/database_helper.dart';
import 'package:flutter_sla_task_tracker/main.dart';
import 'package:flutter_sla_task_tracker/models/task_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> pumpDatabase(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() async {
      await DatabaseHelper.instance.fetchAllTasks();
      await DatabaseHelper.instance.fetchAllMembers();
    });
    await tester.pump();
    await tester.pumpAndSettle();
  }

  setUp(() async {
    final database = await DatabaseHelper.instance.database;
    await database.delete('tasks');
    await database.delete('team_members');
    await DatabaseHelper.instance.insertMember({
      'id': 'member-kenia',
      'name': 'Kenia',
      'role': 'Project lead',
      'email': 'kenia@example.com',
    });

    final today = DateTime.now();
    String dateOffset(int days) {
      final date = today.add(Duration(days: days));
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    final tasks = [
      ('task-overdue', 'Fix Navigation Bug', -2, 'In Progress'),
      ('task-risk', 'Design Login Screen', 1, 'To Do'),
      ('task-track', 'Set Up Database', 5, 'To Do'),
      ('task-complete', 'Create Dashboard', -3, 'Completed'),
    ];
    for (final (id, title, dueInDays, status) in tasks) {
      await DatabaseHelper.instance.insertTask({
        'id': id,
        'title': title,
        'description': '',
        'deadline': dateOffset(dueInDays),
        'status': status,
        'priority': 'Medium',
        'assigned_to_id': 'member-kenia',
      });
    }
  });

  testWidgets('sign-in requires a name', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(find.text('Hi, Esther'), findsNothing);
  });

  test(
    'SLA calculation classifies completed, overdue, at-risk, and on-track',
    () {
      final now = DateTime(2026, 10, 10, 13);
      TaskRecord task(String deadline, String status) => TaskRecord(
        id: 'test',
        title: 'Test',
        deadline: DateTime.parse(deadline),
        status: status,
        priority: 'Low',
      );

      expect(
        task('2026-10-09', 'In Progress').slaStatusAt(now),
        SlaStatus.overdue,
      );
      expect(task('2026-10-12', 'To Do').slaStatusAt(now), SlaStatus.atRisk);
      expect(task('2026-10-13', 'To Do').slaStatusAt(now), SlaStatus.onTrack);
      expect(
        task('2026-10-01', 'Completed').slaStatusAt(now),
        SlaStatus.completed,
      );
    },
  );

  testWidgets('dashboard reads SQLite task progress and SLA counts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField), 'Esther');
    await tester.tap(find.text('Continue to dashboard'));
    await pumpDatabase(tester);

    expect(find.text('Hi, Esther'), findsOneWidget);
    expect(find.text('SLA overview'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('At Risk'), findsOneWidget);
    expect(find.text('On Track'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Fix Navigation Bug'), 300);
    expect(find.text('Fix Navigation Bug'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Design Login Screen'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Design Login Screen'), findsOneWidget);
  });

  testWidgets('Task List shows the same SLA status as the Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField), 'Esther');
    await tester.tap(find.text('Continue to dashboard'));
    await pumpDatabase(tester);

    await tester.tap(find.text('Tasks'));
    await pumpDatabase(tester);

    expect(find.text('Fix Navigation Bug'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Design Login Screen'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Design Login Screen'), findsOneWidget);
    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('Team and Profile tabs are connected to the workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField), 'Esther');
    await tester.tap(find.text('Continue to dashboard'));
    await pumpDatabase(tester);

    await tester.tap(find.text('Team'));
    await pumpDatabase(tester);
    expect(find.text('Kenia'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Display name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bior');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dashboard'));
    await pumpDatabase(tester);
    expect(find.text('Hi, Bior'), findsOneWidget);
  });
}
