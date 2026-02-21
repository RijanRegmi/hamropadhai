import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/core/services/shake_detector.dart';
import 'package:hamropadhai/features/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/routine_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/assignment_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notice_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/pages/notification_screen.dart';
import 'package:hamropadhai/features/dashboard/presentation/services/notification_service.dart';
import 'package:hamropadhai/features/auth/presentation/providers/auth_token_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector(
      onShake: () {
        _onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Refreshing...'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.invalidate(profileProvider);
      final token = await ref.read(authTokenProvider.future);
      if (token != null) {
        await NotificationService.instance.startService(token);
      }
    });
  }

  @override
  void dispose() {
    _shakeDetector.stop();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(profileProvider);
    ref.invalidate(notifUnreadCountProvider);
    await ref.read(profileProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final unreadAsync = ref.watch(notifUnreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final pad = isTablet ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset("assets/images/books.png", height: 24),
        ),
        titleSpacing: 0,
        title: Image.asset(
          "assets/images/HamroPadhai.png",
          height: 22,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
                unreadAsync.maybeWhen(
                  data: (count) => count > 0
                      ? Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(pad),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 720 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileAsync.when(
                      data: (p) => _WelcomeCard(profile: p),
                      loading: () => const _WelcomeCard(profile: {}),
                      error: (_, __) => const _WelcomeCard(profile: {}),
                    ),
                    SizedBox(height: isTablet ? 28 : 24),
                    Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: isTablet ? 14 : 12),
                    GridView.count(
                      crossAxisCount: isTablet ? 4 : 2,
                      crossAxisSpacing: isTablet ? 14 : 12,
                      mainAxisSpacing: isTablet ? 14 : 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isTablet ? 1.25 : 1.15,
                      children: [
                        _DashboardCard(
                          icon: Icons.schedule,
                          title: 'Routine',
                          subtitle: 'View your schedule',
                          bgColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFF59E0B),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoutineScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.assignment_outlined,
                          title: 'Assignment',
                          subtitle: 'Your tasks',
                          bgColor: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssignmentScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          icon: Icons.edit_note,
                          title: 'Exam',
                          subtitle: 'Upcoming exams',
                          bgColor: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF8B5CF6),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exam coming soon!'),
                                ),
                              ),
                        ),
                        _DashboardCard(
                          icon: Icons.campaign_outlined,
                          title: 'Notice',
                          subtitle: 'School notices',
                          bgColor: const Color(0xFFFFEDD5),
                          iconColor: const Color(0xFFF97316),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NoticeScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _WelcomeCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final fullName = profile['fullName'] as String? ?? 'Student';
    final profileImage = profile['profileImage'] as String?;
    final classId = profile['classId'] as String? ?? '';
    final sectionId = profile['sectionId'] as String? ?? '';
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (classId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Class $classId${sectionId.isNotEmpty ? '-$sectionId' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: isTablet ? 42 : 36,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: profileImage != null
                ? NetworkImage('${ApiEndpoints.imageBaseUrl}$profileImage')
                : null,
            child: profileImage == null
                ? Icon(
                    Icons.person,
                    size: isTablet ? 42 : 36,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color bgColor, iconColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : Colors.black.withOpacity(0.06);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 18 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: isTablet ? 22 : 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textSecondary),
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
