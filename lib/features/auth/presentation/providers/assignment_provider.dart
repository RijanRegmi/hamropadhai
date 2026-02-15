import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/assignment_repository.dart';

final assignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.read(assignmentRepositoryProvider);
  return repository.getMyAssignments();
});

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
