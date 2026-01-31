import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/bottom_screen/profile_screen.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';

void main() {
  testWidgets("Should show loading indicator while fetching profile", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("Should have app bar with logo and notification icon", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    expect(find.byType(AppBar), findsOneWidget);

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets(
    "Should display menu tiles for Edit Details, Settings, and Support",
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            (ref) => Future.value({
              'fullName': 'Test User',
              'email': 'test@example.com',
              'username': 'testuser',
              'profileImage': null,
            }),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('Setting'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    },
  );

  testWidgets("Should have Logout button and show confirmation dialog", (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(
          (ref) => Future.value({
            'fullName': 'Test User',
            'email': 'test@example.com',
            'username': 'testuser',
            'profileImage': null,
          }),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    final logoutButtons = find.text('Logout');
    expect(logoutButtons, findsNWidgets(2));
  });

  testWidgets("Should display user profile information", (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(
          (ref) => Future.value({
            'fullName': 'John Doe',
            'email': 'john.doe@example.com',
            'username': 'johndoe123',
            'profileImage': null,
          }),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
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
    "Should show 'Feature coming soon!' snackbar when menu items are tapped",
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            (ref) => Future.value({
              'fullName': 'Test User',
              'email': 'test@example.com',
              'username': 'testuser',
              'profileImage': null,
            }),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Details'));
      await tester.pumpAndSettle();

      expect(find.text('Feature coming soon!'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();

      expect(find.text('Feature coming soon!'), findsOneWidget);
    },
  );

  testWidgets("Should have pull-to-refresh functionality", (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(
          (ref) => Future.value({
            'fullName': 'Test User',
            'email': 'test@example.com',
            'username': 'testuser',
            'profileImage': null,
          }),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
    await tester.pumpAndSettle();
  });
}
