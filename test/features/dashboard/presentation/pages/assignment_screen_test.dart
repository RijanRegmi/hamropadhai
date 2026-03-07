import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/assignment_screen.dart';
import 'package:hamropadhai/features/auth/presentation/providers/assignment_provider.dart';

void main() {
  testWidgets('1. AssignmentScreen shows 4 tabs', (tester) async {
    final container = ProviderContainer(
      overrides: [
        pendingAssignmentsProvider.overrideWith((_) async => []),
        submittedAssignmentsProvider.overrideWith((_) async => []),
        gradedAssignmentsProvider.overrideWith((_) async => []),
        historyAssignmentsProvider.overrideWith((_) async => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AssignmentScreen()),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Graded'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('2. AssignmentScreen shows empty state for pending tab', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        pendingAssignmentsProvider.overrideWith((_) async => []),
        submittedAssignmentsProvider.overrideWith((_) async => []),
        gradedAssignmentsProvider.overrideWith((_) async => []),
        historyAssignmentsProvider.overrideWith((_) async => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AssignmentScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No pending assignments'), findsOneWidget);
    expect(find.text("You're all caught up!"), findsOneWidget);
  });

  testWidgets(
    '3. AssignmentScreen shows assignment card with title and submit button',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pendingAssignmentsProvider.overrideWith(
            (_) async => [
              {
                '_id': 'a1',
                'title': 'Math Homework',
                'subject': 'Math',
                'totalMarks': 20,
                'hasSubmitted': false,
                'isGraded': false,
                'dueDate': DateTime.now()
                    .add(const Duration(days: 2))
                    .toIso8601String(),
              },
            ],
          ),
          submittedAssignmentsProvider.overrideWith((_) async => []),
          gradedAssignmentsProvider.overrideWith((_) async => []),
          historyAssignmentsProvider.overrideWith((_) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AssignmentScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Math Homework'), findsOneWidget);
      expect(find.text('Submit Assignment'), findsOneWidget);
    },
  );

  testWidgets('4. AssignmentScreen AppBar shows title and back icon', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        pendingAssignmentsProvider.overrideWith((_) async => []),
        submittedAssignmentsProvider.overrideWith((_) async => []),
        gradedAssignmentsProvider.overrideWith((_) async => []),
        historyAssignmentsProvider.overrideWith((_) async => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AssignmentScreen()),
      ),
    );

    expect(find.text('Assignments'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
