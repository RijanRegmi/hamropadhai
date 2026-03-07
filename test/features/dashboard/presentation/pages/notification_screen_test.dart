import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notification_screen.dart';
import 'package:hamropadhai/features/auth/presentation/providers/auth_token_provider.dart';

void main() {
  testWidgets('1. NotificationScreen shows AppBar with Notifications title', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith((_) async => []),
        notifUnreadCountProvider.overrideWith((_) => Stream.value(0)),
        authTokenProvider.overrideWith((_) async => 'test_token'),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('2. NotificationScreen shows empty state when no notifications', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith((_) async => []),
        notifUnreadCountProvider.overrideWith((_) => Stream.value(0)),
        authTokenProvider.overrideWith((_) async => 'test_token'),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(
      find.text('Assignment, routine & notice\nalerts will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets(
    '3. NotificationScreen shows unread count and Mark all read button',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (_) async => [
              {
                '_id': 'n1',
                'title': 'New Assignment',
                'message': 'Math assignment has been added.',
                'type': 'assignment_created',
                'isRead': false,
                'createdAt': DateTime.now().toIso8601String(),
              },
            ],
          ),
          notifUnreadCountProvider.overrideWith((_) => Stream.value(1)),
          authTokenProvider.overrideWith((_) async => 'test_token'),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 unread'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    },
  );

  testWidgets(
    '4. NotificationScreen shows notification tile with title and message',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (_) async => [
              {
                '_id': 'n1',
                'title': 'Math Assignment Added',
                'message': 'A new math assignment has been posted.',
                'type': 'assignment_created',
                'isRead': false,
                'createdAt': DateTime.now().toIso8601String(),
              },
            ],
          ),
          notifUnreadCountProvider.overrideWith((_) => Stream.value(1)),
          authTokenProvider.overrideWith((_) async => 'test_token'),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Math Assignment Added'), findsOneWidget);
      expect(
        find.text('A new math assignment has been posted.'),
        findsOneWidget,
      );
      expect(find.text('New Assignment'), findsOneWidget);
    },
  );

  testWidgets('5. NotificationScreen shows correct label for notice type', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith(
          (_) async => [
            {
              '_id': 'n2',
              'title': 'Holiday Notice',
              'message': 'School closed tomorrow.',
              'type': 'notice_created',
              'isRead': true,
              'createdAt': DateTime.now().toIso8601String(),
            },
          ],
        ),
        notifUnreadCountProvider.overrideWith((_) => Stream.value(0)),
        authTokenProvider.overrideWith((_) async => 'test_token'),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New Notice'), findsOneWidget);
    expect(find.text('Holiday Notice'), findsOneWidget);
  });

  testWidgets('6. NotificationScreen has RefreshIndicator', (tester) async {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith((_) async => []),
        notifUnreadCountProvider.overrideWith((_) => Stream.value(0)),
        authTokenProvider.overrideWith((_) async => 'test_token'),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
