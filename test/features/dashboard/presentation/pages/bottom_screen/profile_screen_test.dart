import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/bottom_screen/profile_screen.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';

Widget _buildWithProfile([Map<String, dynamic>? profile]) {
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(
        (ref) => Future.value(
          profile ??
              {
                'fullName': 'Test User',
                'email': 'test@example.com',
                'username': 'testuser',
                'profileImage': null,
              },
        ),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  testWidgets('Should show loading indicator while fetching profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Should have app bar with logo and settings icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets(
    'Should display menu tiles for Edit Details, Settings, and Support',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildWithProfile());
      await tester.pumpAndSettle();

      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('Setting'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    },
  );

  testWidgets('Should have Logout button and show confirmation dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildWithProfile());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Logout').first,
      100,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Logout').first);
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Logout'), findsNWidgets(3));
  });

  testWidgets('Should display user profile information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildWithProfile({
        'fullName': 'John Doe',
        'email': 'john.doe@example.com',
        'username': 'johndoe123',
        'profileImage': null,
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john.doe@example.com'), findsOneWidget);
    expect(find.text('johndoe123'), findsOneWidget);
    expect(find.text('HamroPadhai'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets(
    "Should show 'Feature coming soon!' snackbar when Support is tapped",
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildWithProfile());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Support'));
      await tester.pump();

      expect(find.text('Feature coming soon!'), findsOneWidget);
    },
  );

  testWidgets('Should have pull-to-refresh functionality', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildWithProfile());
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pumpAndSettle();
  });
}
