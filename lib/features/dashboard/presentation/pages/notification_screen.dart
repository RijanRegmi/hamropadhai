import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hamropadhai/features/auth/presentation/providers/auth_token_provider.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';

import 'package:hamropadhai/features/dashboard/presentation/pages/assignment_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notice_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/routine_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final token = await ref.watch(authTokenProvider.future);
      if (token == null) throw Exception('Not logged in');
      final res = await http
          .get(
            Uri.parse('${ApiEndpoints.imageBaseUrl}/api/student/notifications'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) throw Exception(body['message'] ?? 'Failed');
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    });

final notifUnreadCountProvider = StreamProvider<int>((ref) async* {
  Future<int> fetch() async {
    try {
      final token = await ref.read(authTokenProvider.future);
      if (token == null) return 0;
      final res = await http
          .get(
            Uri.parse(
              '${ApiEndpoints.imageBaseUrl}/api/student/notifications/unread-count',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data']?['unreadCount'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  yield await fetch();

  await for (final _ in Stream.periodic(const Duration(seconds: 15))) {
    yield await fetch();
  }
});

// ── Type metadata ─────────────────────────────────────────────────────────────
class _Meta {
  final Color color, bg;
  final IconData icon;
  final String label;
  const _Meta(this.color, this.bg, this.icon, this.label);
}

_Meta _metaFor(String type) {
  switch (type) {
    case 'assignment_created':
      return const _Meta(
        Color(0xFF3B82F6),
        Color(0xFFDBEAFE),
        Icons.assignment_add,
        'New Assignment',
      );
    case 'assignment_updated':
      return const _Meta(
        Color(0xFF7C3AED),
        Color(0xFFEDE9FE),
        Icons.assignment_turned_in_outlined,
        'Assignment Updated',
      );
    case 'routine_created':
      return const _Meta(
        Color(0xFFF59E0B),
        Color(0xFFFEF3C7),
        Icons.calendar_today_outlined,
        'New Routine',
      );
    case 'routine_updated':
      return const _Meta(
        Color(0xFFEA580C),
        Color(0xFFFFEDD5),
        Icons.edit_calendar_outlined,
        'Routine Updated',
      );
    case 'notice_created':
      return const _Meta(
        Color(0xFF10B981),
        Color(0xFFD1FAE5),
        Icons.campaign_outlined,
        'New Notice',
      );
    case 'notice_updated':
      return const _Meta(
        Color(0xFF059669),
        Color(0xFFD1FAE5),
        Icons.campaign_rounded,
        'Notice Updated',
      );
    default:
      return const _Meta(
        Color(0xFF7C3AED),
        Color(0xFFEDE9FE),
        Icons.notifications_outlined,
        'Notification',
      );
  }
}

void _navigateByType(BuildContext context, String type) {
  switch (type) {
    case 'assignment_created':
    case 'assignment_updated':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssignmentScreen()),
      );
      break;
    case 'notice_created':
    case 'notice_updated':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoticeScreen()),
      );
      break;
    case 'routine_created':
    case 'routine_updated':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoutineScreen()),
      );
      break;
    default:
      break;
  }
}

String _timeAgo(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const mo = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${mo[d.month]}';
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  Future<void> _markAll(WidgetRef ref, String token) async {
    try {
      await http
          .post(
            Uri.parse(
              '${ApiEndpoints.imageBaseUrl}/api/student/notifications/mark-all-read',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      ref.invalidate(notificationsProvider);
      ref.invalidate(notifUnreadCountProvider);
    } catch (_) {}
  }

  Future<void> _markOne(WidgetRef ref, String token, String id) async {
    try {
      await http
          .post(
            Uri.parse(
              '${ApiEndpoints.imageBaseUrl}/api/student/notifications/$id/mark-read',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      ref.invalidate(notificationsProvider);
      ref.invalidate(notifUnreadCountProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(notificationsProvider);
    final unread = ref.watch(notifUnreadCountProvider);
    final String? token = ref
        .watch(authTokenProvider)
        .when(data: (t) => t, loading: () => null, error: (_, __) => null);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF0F0F0F)
        : const Color(0xFFF2F3F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            unread.maybeWhen(
              data: (n) => n > 0
                  ? Text(
                      '$n unread',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C3AED),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          if (token != null)
            unread.maybeWhen(
              data: (n) => n > 0
                  ? TextButton(
                      onPressed: () => _markAll(ref, token),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(notifUnreadCountProvider);
        },
        child: asyncList.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
          error: (e, _) => _Centred(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (list) => list.isEmpty
              ? _Centred(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF7C3AED),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assignment, routine & notice\nalerts will appear here.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 74,
                    endIndent: 16,
                    color: isDark ? const Color(0xFF2E2E2E) : null,
                  ),
                  itemBuilder: (_, i) => _Tile(
                    n: list[i],
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      if (token != null && list[i]['isRead'] != true) {
                        _markOne(ref, token, list[i]['_id'] as String);
                      }
                      _navigateByType(
                        context,
                        list[i]['type'] as String? ?? '',
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _Centred extends StatelessWidget {
  final Widget child;
  const _Centred({required this.child});
  @override
  Widget build(BuildContext ctx) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.75,
      child: Center(child: child),
    ),
  );
}

class _Tile extends StatelessWidget {
  final Map<String, dynamic> n;
  final VoidCallback onTap;
  final bool isDark;
  final Color textPrimary, textSecondary;

  const _Tile({
    required this.n,
    required this.onTap,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final title = n['title'] as String? ?? '';
    final message = n['message'] as String? ?? '';
    final type = n['type'] as String? ?? '';
    final isRead = n['isRead'] == true;
    final createdAt = n['createdAt'] as String?;
    final meta = _metaFor(type);

    // ✅ Unread bg adapts: purple tint in light, subtle dark card in dark
    final tileBg = isRead
        ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
        : (isDark ? const Color(0xFF1A1230) : const Color(0xFFFAF7FF));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: tileBg,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: meta.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, color: meta.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: meta.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: meta.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(createdAt),
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
