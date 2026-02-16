import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamropadhai/features/auth/presentation/providers/assignment_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const List<String> _weekDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-reload on every visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(assignmentsProvider);
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(assignmentsProvider);
    await ref.read(assignmentsProvider.future);
  }

  DateTime get _firstDayOfMonth =>
      DateTime(_focusedDay.year, _focusedDay.month, 1);
  int get _startWeekday => _firstDayOfMonth.weekday % 7;
  int get _daysInMonth =>
      DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;

  String _dayKey(int day) => '${_focusedDay.year}-${_focusedDay.month}-$day';

  String _selectedKey() {
    if (_selectedDay == null) return '';
    return '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}';
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return _focusedDay.year == now.year &&
        _focusedDay.month == now.month &&
        day == now.day;
  }

  bool _isSelected(int day) {
    if (_selectedDay == null) return false;
    return _selectedDay!.year == _focusedDay.year &&
        _selectedDay!.month == _focusedDay.month &&
        _selectedDay!.day == day;
  }

  void _prevMonth() => setState(() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    _selectedDay = null;
  });

  void _nextMonth() => setState(() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    _selectedDay = null;
  });

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final assignmentsByDate = ref.watch(assignmentsByDateProvider);
    final selectedAssignments = _selectedDay != null
        ? (assignmentsByDate[_selectedKey()] ?? [])
        : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/books.png', height: 24),
        ),
        titleSpacing: 0,
        title: Image.asset(
          'assets/images/HamroPadhai.png',
          height: 22,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: _onRefresh,
          child: assignmentsAsync.hasError
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            assignmentsAsync.error.toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _onRefresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (assignmentsAsync.isLoading) ...[
                        const LinearProgressIndicator(
                          color: Color(0xFF7C3AED),
                          backgroundColor: Color(0xFFEDE9FE),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _prevMonth,
                                  color: const Color(0xFF7C3AED),
                                ),
                                Text(
                                  '${_months[_focusedDay.month - 1]} ${_focusedDay.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _nextMonth,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: _weekDays
                                  .map(
                                    (d) => Expanded(
                                      child: Center(
                                        child: Text(
                                          d,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: d == 'Sun' || d == 'Sat'
                                                ? const Color(0xFF7C3AED)
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: _startWeekday + _daysInMonth,
                              itemBuilder: (context, index) {
                                if (index < _startWeekday) {
                                  return const SizedBox.shrink();
                                }
                                final day = index - _startWeekday + 1;
                                final isToday = _isToday(day);
                                final isSelected = _isSelected(day);
                                final hasAssignment = assignmentsByDate
                                    .containsKey(_dayKey(day));

                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedDay = DateTime(
                                      _focusedDay.year,
                                      _focusedDay.month,
                                      day,
                                    );
                                  }),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF7C3AED)
                                              : isToday
                                              ? const Color(0xFFEDE9FE)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$day',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isToday || isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isToday
                                                  ? const Color(0xFF7C3AED)
                                                  : const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: hasAssignment
                                              ? const Color(0xFF3B82F6)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedDay != null) ...[
                        Text(
                          '${_months[_selectedDay!.month - 1]} ${_selectedDay!.day}, ${_selectedDay!.year}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedAssignments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF7C3AED),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'No assignments due this day',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...selectedAssignments.map(
                            (a) => _AssignmentCard(assignment: a),
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final title = assignment['title'] ?? 'Untitled';
    final subject = assignment['subject'] ?? '';
    final totalMarks = assignment['totalMarks']?.toString() ?? '0';
    final hasSubmitted = assignment['hasSubmitted'] == true;
    final isGraded = assignment['isGraded'] == true;

    Color statusColor;
    String statusText;
    Color statusBg;

    if (isGraded) {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusText = 'Graded';
    } else if (hasSubmitted) {
      statusColor = const Color(0xFF3B82F6);
      statusBg = const Color(0xFFDBEAFE);
      statusText = 'Submitted';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFEF3C7);
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$subject · $totalMarks marks',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
