import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/bottom_screen/home_screen.dart';

void main() {
  testWidgets('DashboardScreen renders tiles and handles tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Routine'), findsOneWidget);
    expect(find.text('Assignment'), findsOneWidget);
    expect(find.text('Exam'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Announcement'), findsOneWidget);

    await tester.tap(find.text('Routine'));
    await tester.pump();

    expect(find.text('Routine feature coming soon!'), findsOneWidget);
  });
}
