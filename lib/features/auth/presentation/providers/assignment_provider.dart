import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/remote/assignment_remote_datasource.dart';
import 'auth_token_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final _remoteProvider = Provider(
  (_) => AssignmentRemoteDatasource(http.Client()),
);

// ── Providers ─────────────────────────────────────────────────────────────────

final assignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  return ref.read(_remoteProvider).getMyAssignments(token);
});

final pendingAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  return ref.read(_remoteProvider).getPendingAssignments(token);
});

final submittedAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final token = await ref.watch(authTokenProvider.future);
    if (token == null) throw Exception('Not logged in');
    return ref.read(_remoteProvider).getSubmittedAssignments(token);
  },
);

final gradedAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  return ref.read(_remoteProvider).getGradedAssignments(token);
});

final historyAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  return ref.read(_remoteProvider).getHistoryAssignments(token);
});

// Used by calendar — keeps existing functionality
final assignmentsByDateProvider =
    Provider<Map<String, List<Map<String, dynamic>>>>((ref) {
      final assignmentsAsync = ref.watch(assignmentsProvider);
      return assignmentsAsync.when(
        data: (assignments) {
          final Map<String, List<Map<String, dynamic>>> map = {};
          for (final a in assignments) {
            final dueDate = a['dueDate'];
            if (dueDate == null) continue;
            final day = DateTime.parse(dueDate).toLocal();
            final key = '${day.year}-${day.month}-${day.day}';
            map.putIfAbsent(key, () => []).add(a);
          }
          return map;
        },
        loading: () => {},
        error: (_, __) => {},
      );
    });
