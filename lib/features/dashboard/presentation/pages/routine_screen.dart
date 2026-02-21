import 'package:flutter/material.dart';
import 'package:hamropadhai/core/services/shake_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/routine_provider.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  late ShakeDetector _shakeDetector;
  static const List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  String _selectedDay = '';
  late final String _today;
  late final String _tomorrow;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = _days[now.weekday % 7];
    _tomorrow = _days[(now.weekday + 1) % 7];
    _selectedDay = _today;
    _shakeDetector = ShakeDetector(
      onShake: () {
        ref.invalidate(routineProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Refreshing routine...'),
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
    final routineAsync = ref.watch(routineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5);
    final headerBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Class Routine',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: routineAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (error, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.refresh(routineProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (routine) {
          final entries = (routine['entries'] as List<dynamic>? ?? []);
          final classId = routine['classId'] ?? '';
          final sectionId = routine['sectionId'] ?? '';
          final academicYear = routine['academicYear'] ?? '';
          final availableDays = entries.map((e) => e['day'] as String).toList();

          Map<String, dynamic>? selectedEntry;
          try {
            selectedEntry =
                entries.firstWhere((e) => e['day'] == _selectedDay)
                    as Map<String, dynamic>?;
          } catch (_) {
            selectedEntry = null;
          }

          final periods = selectedEntry != null
              ? (selectedEntry['periods'] as List<dynamic>? ?? [])
              : <dynamic>[];

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: headerBg,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Class $classId-$sectionId',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            academicYear,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _days.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final day = _days[index];
                            final isSelected = day == _selectedDay;
                            final hasData = availableDays.contains(day);
                            final isToday = day == _today;
                            final isTomorrow = day == _tomorrow;

                            Color bgColor;
                            Color textColor;
                            if (isSelected) {
                              bgColor = const Color(0xFF7C3AED);
                              textColor = Colors.white;
                            } else if (isToday && hasData) {
                              bgColor = isDark
                                  ? const Color(0xFF064E3B)
                                  : const Color(0xFFD1FAE5);
                              textColor = isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF065F46);
                            } else if (isTomorrow && hasData) {
                              bgColor = isDark
                                  ? const Color(0xFF78350F)
                                  : const Color(0xFFFEF9C3);
                              textColor = isDark
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF854D0E);
                            } else if (hasData) {
                              bgColor = isDark
                                  ? const Color(0xFF2D1B69)
                                  : const Color(0xFFEDE9FE);
                              textColor = const Color(0xFF7C3AED);
                            } else {
                              bgColor = isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey[100]!;
                              textColor = isDark
                                  ? Colors.grey[600]!
                                  : Colors.grey[400]!;
                            }

                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  day.substring(0, 3),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: periods.isEmpty
                      ? RefreshIndicator(
                          color: const Color(0xFF7C3AED),
                          onRefresh: () async => ref.refresh(routineProvider),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2D1B69)
                                            : const Color(0xFFEDE9FE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.event_busy_outlined,
                                        color: Color(0xFF7C3AED),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No classes scheduled',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Enjoy your free day!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF7C3AED),
                          onRefresh: () async => ref.refresh(routineProvider),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: periods.length,
                            itemBuilder: (context, index) {
                              final period =
                                  periods[index] as Map<String, dynamic>;
                              return _PeriodCard(
                                period: period,
                                isFirst: index == 0,
                                isLast: index == periods.length - 1,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final Map<String, dynamic> period;
  final bool isFirst, isLast;
  const _PeriodCard({
    required this.period,
    required this.isFirst,
    required this.isLast,
  });

  Color _subjectColor(String subject) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF84CC16),
    ];
    return colors[subject.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final divColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey[100]!;

    final periodNumber = period['periodNumber']?.toString() ?? '';
    final subject = period['subject'] as String? ?? 'Unknown';
    final teacherName = period['teacherName'] as String? ?? '';
    final startTime = period['startTime'] as String? ?? '';
    final endTime = period['endTime'] as String? ?? '';
    final roomNumber = period['roomNumber'] as String? ?? '';
    final color = _subjectColor(subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$startTime – $endTime',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Period $periodNumber',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              color: divColor,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (teacherName.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            teacherName,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (roomNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.room_outlined,
                            size: 14,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Room $roomNumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
