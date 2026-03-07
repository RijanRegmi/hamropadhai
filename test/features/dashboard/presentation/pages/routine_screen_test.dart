import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/routine_screen.dart';
import 'package:hamropadhai/features/auth/presentation/providers/routine_provider.dart';

void main() {
  testWidgets('1. RoutineScreen shows AppBar with Class Routine title', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        routineProvider.overrideWith(
          (_) async => {
            'classId': '10',
            'sectionId': 'A',
            'academicYear': '2024-25',
            'entries': [],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Class Routine'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('2. RoutineScreen shows all 7 day chips', (tester) async {
    final container = ProviderContainer(
      overrides: [
        routineProvider.overrideWith(
          (_) async => {
            'classId': '10',
            'sectionId': 'A',
            'academicYear': '2024-25',
            'entries': [],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
  });

  testWidgets('3. RoutineScreen shows class and section info', (tester) async {
    final container = ProviderContainer(
      overrides: [
        routineProvider.overrideWith(
          (_) async => {
            'classId': '10',
            'sectionId': 'A',
            'academicYear': '2024-25',
            'entries': [],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Class 10-A'), findsOneWidget);
    expect(find.text('2024-25'), findsOneWidget);
  });

  testWidgets('4. RoutineScreen shows empty state when no periods scheduled', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        routineProvider.overrideWith(
          (_) async => {
            'classId': '10',
            'sectionId': 'A',
            'academicYear': '2024-25',
            'entries': [],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No classes scheduled'), findsOneWidget);
    expect(find.text('Enjoy your free day!'), findsOneWidget);
  });

  testWidgets('5. RoutineScreen shows period card when data exists', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ][now.weekday % 7];

    final container = ProviderContainer(
      overrides: [
        routineProvider.overrideWith(
          (_) async => {
            'classId': '10',
            'sectionId': 'A',
            'academicYear': '2024-25',
            'entries': [
              {
                'day': today,
                'periods': [
                  {
                    'periodNumber': 1,
                    'subject': 'Mathematics',
                    'teacherName': 'Mr. Sharma',
                    'startTime': '10:00 AM',
                    'endTime': '11:00 AM',
                    'roomNumber': '101',
                  },
                ],
              },
            ],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Mr. Sharma'), findsOneWidget);
    expect(find.text('Room 101'), findsOneWidget);
  });

  testWidgets('6. RoutineScreen shows loading indicator while fetching', (
    tester,
  ) async {
    final completer = Completer<Map<String, dynamic>>();

    final container = ProviderContainer(
      overrides: [routineProvider.overrideWith((_) => completer.future)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RoutineScreen()),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete({});
  });
}
