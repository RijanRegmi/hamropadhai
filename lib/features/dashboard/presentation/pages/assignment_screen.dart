import 'package:flutter/material.dart';
import 'package:hamropadhai/core/services/shake_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../auth/presentation/providers/assignment_provider.dart';
import '../../../auth/presentation/providers/auth_token_provider.dart';

class AssignmentScreen extends ConsumerStatefulWidget {
  const AssignmentScreen({super.key});

  @override
  ConsumerState<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends ConsumerState<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _shakeDetector = ShakeDetector(
      onShake: () {
        _refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Refreshing assignments...'),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shakeDetector.stop();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(pendingAssignmentsProvider);
    ref.invalidate(submittedAssignmentsProvider);
    ref.invalidate(gradedAssignmentsProvider);
    ref.invalidate(historyAssignmentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignments',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey,
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssignmentTab(
            provider: pendingAssignmentsProvider,
            invalidateKey: pendingAssignmentsProvider,
            emptyMessage: 'No pending assignments',
            emptySubtitle: "You're all caught up!",
            emptyIcon: Icons.check_circle_outline,
            showSubmitButton: true,
          ),
          _AssignmentTab(
            provider: submittedAssignmentsProvider,
            invalidateKey: submittedAssignmentsProvider,
            emptyMessage: 'No submitted assignments',
            emptySubtitle: 'Submit your first assignment',
            emptyIcon: Icons.assignment_turned_in_outlined,
          ),
          _AssignmentTab(
            provider: gradedAssignmentsProvider,
            invalidateKey: gradedAssignmentsProvider,
            emptyMessage: 'No graded assignments',
            emptySubtitle: 'Grades will appear here',
            emptyIcon: Icons.grade_outlined,
            showGrade: true,
          ),
          _AssignmentTab(
            provider: historyAssignmentsProvider,
            invalidateKey: historyAssignmentsProvider,
            emptyMessage: 'No past assignments',
            emptySubtitle: 'Completed assignments appear here',
            emptyIcon: Icons.history,
            showGrade: true,
          ),
        ],
      ),
    );
  }
}

class _AssignmentTab extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<Map<String, dynamic>>>> provider;
  final ProviderOrFamily invalidateKey;
  final String emptyMessage, emptySubtitle;
  final IconData emptyIcon;
  final bool showSubmitButton, showGrade;

  const _AssignmentTab({
    required this.provider,
    required this.invalidateKey,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.showSubmitButton = false,
    this.showGrade = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    Future<void> onRefresh() async => ref.invalidate(invalidateKey);

    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: onRefresh,
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (e, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: onRefresh, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
        data: (assignments) => assignments.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
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
                          child: Icon(
                            emptyIcon,
                            color: const Color(0xFF7C3AED),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emptySubtitle,
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) => _AssignmentCard(
                  assignment: assignments[index],
                  showSubmitButton: showSubmitButton,
                  showGrade: showGrade,
                  onRefresh: onRefresh,
                ),
              ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final bool showSubmitButton, showGrade;
  final Future<void> Function() onRefresh;

  const _AssignmentCard({
    required this.assignment,
    required this.showSubmitButton,
    required this.showGrade,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    final title = assignment['title'] ?? 'Untitled';
    final subject = assignment['subject'] ?? '';
    final totalMarks = assignment['totalMarks'] ?? 0;
    final dueDate = assignment['dueDate'];
    final hasSubmitted = assignment['hasSubmitted'] == true;
    final isGraded = assignment['isGraded'] == true;
    final mySubmission = assignment['mySubmission'] as Map<String, dynamic>?;
    final marks = mySubmission?['marks'];
    final feedback = mySubmission?['feedback'] as String?;

    String? formattedDue;
    bool isOverdue = false;
    if (dueDate != null) {
      final due = DateTime.parse(dueDate).toLocal();
      isOverdue = due.isBefore(DateTime.now()) && !hasSubmitted;
      formattedDue =
          '${due.day}/${due.month}/${due.year}  ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
    }

    Color statusColor;
    String statusText;
    Color statusBg;
    if (isGraded) {
      statusColor = const Color(0xFF10B981);
      statusBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      statusText = 'Graded';
    } else if (hasSubmitted) {
      statusColor = const Color(0xFF3B82F6);
      statusBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
      statusText = 'Submitted';
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusBg = isDark ? const Color(0xFF4B1818) : const Color(0xFFFEE2E2);
      statusText = 'Overdue';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusBg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
      statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(
            assignment: assignment,
            onRefresh: onRefresh,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D1B69)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subject · $totalMarks marks',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            if (formattedDue != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: isOverdue
                        ? Colors.red
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: $formattedDue',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : textSecondary,
                      fontWeight: isOverdue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if (showGrade && isGraded && marks != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Grade: $marks / $totalMarks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6EE7B7),
                      ),
                    ),
                    if (feedback != null && feedback.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '· $feedback',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6EE7B7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (showSubmitButton && !hasSubmitted && !isOverdue) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignmentDetailScreen(
                        assignment: assignment,
                        onRefresh: onRefresh,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Submit Assignment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> assignment;
  final Future<void> Function() onRefresh;
  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.onRefresh,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  final _textController = TextEditingController();
  bool _submitting = false;
  List<PlatformFile> _pickedFiles = [];
  static const String _baseUrl = 'http://10.0.2.2:5050';

  @override
  void initState() {
    super.initState();
    final mySubmission =
        widget.assignment['mySubmission'] as Map<String, dynamic>?;
    if (mySubmission != null)
      _textController.text = mySubmission['textContent'] ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null)
        setState(() => _pickedFiles = [..._pickedFiles, ...result.files]);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open file picker: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null)
        setState(() => _pickedFiles = [..._pickedFiles, ...result.files]);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open image picker: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  void _removeFile(int index) => setState(() => _pickedFiles.removeAt(index));

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty && _pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or attach a file before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = await ref.read(authTokenProvider.future);
      if (token == null) throw Exception('Not logged in');
      final assignmentId = widget.assignment['_id'] as String;
      final uri = Uri.parse('$_baseUrl/api/assignments/$assignmentId/submit');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';
      if (_textController.text.trim().isNotEmpty)
        request.fields['textContent'] = _textController.text.trim();
      for (final file in _pickedFiles) {
        if (file.path != null)
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file.path!,
              filename: file.name,
            ),
          );
      }
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _pickedFiles = []);
          await widget.onRefresh();
          Navigator.pop(context);
        }
      } else {
        throw Exception(decoded['message'] ?? 'Failed to submit');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openFile(String fileUrl) async {
    final fullUrl = '$_baseUrl$fileUrl';
    final token = await ref.read(authTokenProvider.future);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Downloading file...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );
    try {
      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200)
        throw Exception('Server returned ${response.statusCode}');
      final fileName = fileUrl.split('/').last;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No app found to open this file type: ${result.message}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download: ${e.toString().replaceFirst('Exception: ', '')}',
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

    final a = widget.assignment;
    final title = a['title'] ?? 'Untitled';
    final description = a['description'] ?? '';
    final subject = a['subject'] ?? '';
    final totalMarks = a['totalMarks'] ?? 0;
    final dueDate = a['dueDate'];
    final hasSubmitted = a['hasSubmitted'] == true;
    final isGraded = a['isGraded'] == true;
    final mySubmission = a['mySubmission'] as Map<String, dynamic>?;
    final marks = mySubmission?['marks'];
    final feedback = mySubmission?['feedback'] as String?;
    final submittedText = mySubmission?['textContent'] as String?;
    final submittedAt = mySubmission?['submittedAt'];
    final submittedFiles =
        (mySubmission?['files'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final attachments =
        (a['attachments'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];

    String? formattedDue;
    bool isOverdue = false;
    if (dueDate != null) {
      final due = DateTime.parse(dueDate).toLocal();
      isOverdue = due.isBefore(DateTime.now()) && !hasSubmitted;
      formattedDue =
          '${due.day}/${due.month}/${due.year}  ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignment Details',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient card — always purple, fine in dark mode
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PillChip(label: subject, light: true),
                      const SizedBox(width: 8),
                      _PillChip(label: '$totalMarks marks', light: true),
                    ],
                  ),
                  if (formattedDue != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: isOverdue ? Colors.red[200] : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: $formattedDue',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red[200] : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (description.isNotEmpty) ...[
              _Section(
                title: 'Description',
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (attachments.isNotEmpty) ...[
              _Section(
                title: 'Attached Files',
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                child: Column(
                  children: attachments
                      .map(
                        (f) => _FileChip(
                          fileName: f['fileName'] ?? 'File',
                          fileType: f['fileType'] ?? 'other',
                          onTap: () => _openFile(f['fileUrl'] ?? ''),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (isGraded && marks != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF065F46)
                        : const Color(0xFF6EE7B7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Grade',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$marks / $totalMarks',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                      ],
                    ),
                    if (feedback != null && feedback.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF065F46)),
                      const SizedBox(height: 4),
                      Text(
                        'Feedback: $feedback',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6EE7B7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (hasSubmitted && mySubmission != null) ...[
              _Section(
                title: 'My Submission',
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (submittedAt != null)
                      Text(
                        'Submitted on ${_formatDate(submittedAt.toString())}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    if (submittedText != null && submittedText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2D1B69)
                              : const Color(0xFFF8F7FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF4C1D95)
                                : const Color(0xFFEDE9FE),
                          ),
                        ),
                        child: Text(
                          submittedText,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (submittedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Submitted files:',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      ...submittedFiles.map(
                        (f) => _FileChip(
                          fileName: f['fileName'] ?? 'File',
                          fileType: f['fileType'] ?? 'other',
                          onTap: () => _openFile(f['fileUrl'] ?? ''),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (!isOverdue) ...[
              _Section(
                title: hasSubmitted
                    ? 'Resubmit Assignment'
                    : 'Submit Assignment',
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Write your answer here (optional)...',
                        hintStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2D1B69)
                            : const Color(0xFFF8F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF4C1D95)
                                : const Color(0xFFEDE9FE),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF4C1D95)
                                : const Color(0xFFEDE9FE),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AttachButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Photos',
                            onTap: _pickImages,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AttachButton(
                            icon: Icons.attach_file,
                            label: 'Any File',
                            onTap: _pickFiles,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Photos (JPG, PNG) · Any file (PDF, DOC, PPT…) · Max 10MB each',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    if (_pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._pickedFiles.asMap().entries.map(
                        (e) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D1B69)
                                : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                size: 18,
                                color: Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.value.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${((e.value.size) / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeFile(e.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                hasSubmitted
                                    ? 'Resubmit Assignment'
                                    : 'Submit Assignment',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!hasSubmitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4B1818)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Deadline passed — submission closed',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _AttachButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D1B69) : const Color(0xFFF3EEFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String fileName, fileType;
  final VoidCallback onTap;
  const _FileChip({
    required this.fileName,
    required this.fileType,
    required this.onTap,
  });

  IconData get _icon {
    switch (fileType) {
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
    switch (fileType) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: _color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.download_outlined, color: _color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Color cardColor, borderColor, textPrimary;
  const _Section({
    required this.title,
    required this.child,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool light;
  const _PillChip({required this.label, this.light = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.2) : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: light ? Colors.white : const Color(0xFF7C3AED),
        ),
      ),
    );
  }
}
