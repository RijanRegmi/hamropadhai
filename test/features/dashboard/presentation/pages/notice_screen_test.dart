import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notice_screen.dart';
import 'package:hamropadhai/features/auth/presentation/providers/notice_provider.dart';

void main() {
  testWidgets('1. NoticeScreen shows AppBar with Notices title', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        myNoticesProvider.overrideWith((_) async => []),
        unreadCountProvider.overrideWith((_) async => 0),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );

    expect(find.text('Notices'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('2. NoticeScreen shows filter bar with all filter chips', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        myNoticesProvider.overrideWith((_) async => []),
        unreadCountProvider.overrideWith((_) async => 0),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
  });

  testWidgets('3. NoticeScreen shows empty state when no notices exist', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        myNoticesProvider.overrideWith((_) async => []),
        unreadCountProvider.overrideWith((_) async => 0),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No notices'), findsOneWidget);
    expect(find.text('Nothing in this category yet.'), findsOneWidget);
  });

  testWidgets(
    '4. NoticeScreen shows unread badge when unread count is greater than 0',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          myNoticesProvider.overrideWith((_) async => []),
          unreadCountProvider.overrideWith((_) async => 3),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NoticeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 unread'), findsOneWidget);
    },
  );

  testWidgets('5. NoticeScreen has RefreshIndicator', (tester) async {
    final container = ProviderContainer(
      overrides: [
        myNoticesProvider.overrideWith((_) async => []),
        unreadCountProvider.overrideWith((_) async => 0),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('6. NoticeScreen shows notice card when data exists', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        myNoticesProvider.overrideWith(
          (_) async => [
            {
              '_id': 'n1',
              'title': 'School Holiday',
              'content':
                  'School will be closed tomorrow due to national holiday.',
              'priority': 'high',
              'hasRead': false,
              'isPinned': false,
              'createdAt': DateTime.now().toIso8601String(),
              'createdBy': {'fullName': 'Admin', 'profileImage': null},
              'attachments': [],
            },
          ],
        ),
        unreadCountProvider.overrideWith((_) async => 1),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NoticeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
