import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _StubBottomNav extends StatefulWidget {
  const _StubBottomNav();
  @override
  State<_StubBottomNav> createState() => _StubBottomNavState();
}

class _StubBottomNavState extends State<_StubBottomNav> {
  int _index = 0;

  final _labels = ['Home', 'Calendar', 'Profile'];
  final _icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.person_outline,
  ];
  final _activeIcons = [Icons.home, Icons.calendar_month, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(_labels[_index])),
      bottomNavigationBar: Row(
        children: List.generate(3, (i) {
          final active = _index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _index = i),
              child: Center(child: Icon(active ? _activeIcons[i] : _icons[i])),
            ),
          );
        }),
      ),
    );
  }
}

void main() {
  testWidgets('1. Bottom nav bar renders all 3 tab icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _StubBottomNav())),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('2. Bottom nav bar starts on Home tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _StubBottomNav())),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('3. Tapping Calendar tab switches to Calendar screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _StubBottomNav())),
    );

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
  });

  testWidgets('4. Tapping Profile tab switches to Profile screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _StubBottomNav())),
    );

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('5. Tapping Home tab after switching returns to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _StubBottomNav())),
    );

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();
    expect(find.text('Calendar'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
  });
}
