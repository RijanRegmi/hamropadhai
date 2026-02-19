import 'package:flutter/material.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/core/services/shake_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:hamropadhai/features/auth/data/repositories/notice_repository.dart';
import 'package:hamropadhai/features/auth/presentation/providers/auth_token_provider.dart';
import 'package:hamropadhai/features/auth/presentation/providers/notice_provider.dart';

String get _base => ApiEndpoints.imageBaseUrl;

Color _priorityColor(String p) {
  switch (p) {
    case 'high':
    case 'urgent':
      return const Color(0xFFEF4444);
    case 'low':
      return const Color(0xFF10B981);
    default:
      return const Color(0xFF7C3AED);
  }
}

String _priorityLabel(String p) => p[0].toUpperCase() + p.substring(1);

class NoticeScreen extends ConsumerStatefulWidget {
  const NoticeScreen({super.key});
  @override
  ConsumerState<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends ConsumerState<NoticeScreen> {
  String _filter = 'all';
  late ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector(
      onShake: () {
        ref.invalidate(myNoticesProvider);
        ref.invalidate(unreadCountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Refreshing notices...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
    _shakeDetector.start();
  }

  @override
  void dispose() {
    _shakeDetector.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myNoticesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notices',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer(
            builder: (ctx, r, _) {
              return r
                  .watch(unreadCountProvider)
                  .maybeWhen(
                    data: (n) => n > 0
                        ? Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$n unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    orElse: () => const SizedBox(),
                  );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _FilterBar(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        onRefresh: () async {
          ref.invalidate(myNoticesProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
          error: (e, _) => _ErrorState(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(myNoticesProvider),
          ),
          data: (notices) {
            final filtered = _applyFilter(notices, _filter);
            if (filtered.isEmpty) return _EmptyState(filter: _filter);
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _NoticeCard(
                notice: filtered[i],
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailScreen(notice: filtered[i]),
                      ),
                    ).then((_) {
                      ref.invalidate(myNoticesProvider);
                      ref.invalidate(unreadCountProvider);
                    }),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> notices,
    String filter,
  ) {
    switch (filter) {
      case 'unread':
        return notices.where((n) => n['hasRead'] != true).toList();
      case 'pinned':
        return notices.where((n) => n['isPinned'] == true).toList();
      case 'high':
        return notices
            .where((n) => n['priority'] == 'high' || n['priority'] == 'urgent')
            .toList();
      case 'low':
        return notices.where((n) => n['priority'] == 'low').toList();
      default:
        return notices;
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const filters = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('pinned', 'Pinned'),
      ('high', 'High'),
      ('low', 'Low'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final active = selected == f.$1;
            return GestureDetector(
              onTap: () => onChanged(f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF7C3AED)
                      : (isDark
                            ? const Color(0xFF2E2E2E)
                            : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Map<String, dynamic> notice;
  final VoidCallback onTap;
  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final unreadBg = isDark ? const Color(0xFF1A1230) : const Color(0xFFFAF7FF);

    final title = notice['title'] as String? ?? 'Untitled';
    final content = notice['content'] as String? ?? '';
    final priority = notice['priority'] as String? ?? 'medium';
    final hasRead = notice['hasRead'] == true;
    final isPinned = notice['isPinned'] == true;
    final createdAt = notice['createdAt'] as String?;
    final createdBy = notice['createdBy'] as Map<String, dynamic>?;
    final attachments = (notice['attachments'] as List<dynamic>?) ?? [];
    final adminName = createdBy?['fullName'] as String? ?? 'Admin';
    final adminImage = createdBy?['profileImage'] as String?;

    String formattedDate = '';
    if (createdAt != null) {
      final d = DateTime.parse(createdAt).toLocal();
      const months = [
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
      final hour = d.hour > 12
          ? d.hour - 12
          : d.hour == 0
          ? 12
          : d.hour;
      final min = d.minute.toString().padLeft(2, '0');
      final amPm = d.hour >= 12 ? 'PM' : 'AM';
      formattedDate =
          '${d.day} ${months[d.month]} ${d.year} – $hour:$min $amPm';
    }

    final pColor = _priorityColor(priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: hasRead ? cardBg : unreadBg,
          border: Border(
            left: BorderSide(
              color: hasRead ? Colors.transparent : const Color(0xFF7C3AED),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AdminAvatar(
                    imageUrl: adminImage != null ? '$_base$adminImage' : null,
                    name: adminName,
                    size: 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!hasRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adminName,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isPinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _priorityLabel(priority),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: content.length > 140
                          ? '${content.substring(0, 140)}... '
                          : content,
                    ),
                    if (content.length > 140)
                      const TextSpan(
                        text: 'Read More',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (attachments.isNotEmpty) ...[
                    Icon(
                      Icons.attach_file,
                      size: 13,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${attachments.length} attachment${attachments.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  const _AdminAvatar({
    required this.imageUrl,
    required this.name,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEDE9FE),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialsAvatar(initials: initials, size: size),
              )
            : _InitialsAvatar(initials: initials, size: size),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const _InitialsAvatar({required this.initials, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    color: const Color(0xFFEDE9FE),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF7C3AED),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D1B69)
                      : const Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF7C3AED),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No notices',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                filter == 'unread'
                    ? "You've read all notices!"
                    : 'Nothing in this category yet.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailScreen({super.key, required this.notice});
  @override
  ConsumerState<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends ConsumerState<NoticeDetailScreen> {
  bool _markingRead = false;
  late Map<String, dynamic> _notice;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    if (_notice['hasRead'] != true)
      WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  Future<void> _markAsRead() async {
    if (_markingRead) return;
    setState(() => _markingRead = true);
    try {
      final token = await ref.read(authTokenProvider.future);
      if (token == null) return;
      await ref
          .read(noticeRepositoryProvider)
          .markAsRead(token, _notice['_id'] as String);
      if (mounted) {
        setState(() => _notice = {..._notice, 'hasRead': true});
        ref.invalidate(unreadCountProvider);
        ref.invalidate(myNoticesProvider);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _openFile(String fileUrl, String fileName) async {
    final token = await ref.read(authTokenProvider.future);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Downloading...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );
    try {
      final res = await http
          .get(
            Uri.parse('$_base$fileUrl'),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('Server error');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(res.bodyBytes);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: ${result.message}')),
        );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : Colors.black.withOpacity(0.06);

    final title = _notice['title'] as String? ?? 'Untitled';
    final content = _notice['content'] as String? ?? '';
    final priority = _notice['priority'] as String? ?? 'medium';
    final hasRead = _notice['hasRead'] == true;
    final isPinned = _notice['isPinned'] == true;
    final createdAt = _notice['createdAt'] as String?;
    final createdBy = _notice['createdBy'] as Map<String, dynamic>?;
    final attachments = ((_notice['attachments'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
    final adminName = createdBy?['fullName'] as String? ?? 'Admin';
    final adminImage = createdBy?['profileImage'] as String?;
    final adminEmail = createdBy?['email'] as String?;
    final adminRole = createdBy?['role'] as String? ?? 'admin';
    final pColor = _priorityColor(priority);

    String formattedDate = '';
    if (createdAt != null) {
      final d = DateTime.parse(createdAt).toLocal();
      const months = [
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
      final hour = d.hour > 12
          ? d.hour - 12
          : d.hour == 0
          ? 12
          : d.hour;
      final min = d.minute.toString().padLeft(2, '0');
      final amPm = d.hour >= 12 ? 'PM' : 'AM';
      formattedDate = '${d.day} ${months[d.month]} ${d.year}  $hour:$min $amPm';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notice Detail',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hasRead)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Read',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Posted by card
            Container(
              color: cardColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _AdminAvatar(
                    imageUrl: adminImage != null ? '$_base$adminImage' : null,
                    name: adminName,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                adminRole[0].toUpperCase() +
                                    adminRole.substring(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (adminEmail != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  adminEmail,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _priorityLabel(priority),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: pColor,
                          ),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: Color(0xFF7C3AED),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 3, color: pColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                  height: 1.7,
                ),
              ),
            ),
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...attachments.map(
                      (f) => _FileChip(
                        file: f,
                        onTap: () => _openFile(
                          f['fileUrl'] ?? '',
                          f['fileName'] ?? 'file',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!hasRead) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _markingRead ? null : _markAsRead,
                    icon: _markingRead
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: const Text('Mark as Read'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onTap;
  const _FileChip({required this.file, required this.onTap});

  IconData get _icon {
    switch (file['fileType'] as String? ?? '') {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'presentation':
        return Icons.slideshow_outlined;
      case 'spreadsheet':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color get _color {
    switch (file['fileType'] as String? ?? '') {
      case 'image':
        return const Color(0xFF3B82F6);
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'document':
        return const Color(0xFF3B82F6);
      case 'presentation':
        return const Color(0xFFF59E0B);
      case 'spreadsheet':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = file['fileSize'] as num?;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['fileName'] ?? 'File',
                    style: TextStyle(
                      fontSize: 13,
                      color: _color,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (size != null)
                    Text(
                      '${(size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            Icon(Icons.download_outlined, color: _color, size: 18),
          ],
        ),
      ),
    );
  }
}
