import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/bottom_navigation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('BottomNavigationScreen shows all tabs and switches screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BottomNavigationScreen())),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
  });
}
