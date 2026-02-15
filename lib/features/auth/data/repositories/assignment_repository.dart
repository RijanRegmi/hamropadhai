import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../auth/data/datasources/local/auth_local_datasource.dart';
import '../datasources/remote/assignment_remote_datasource.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(
    remote: AssignmentRemoteDatasource(http.Client()),
    local: AuthLocalDatasource(),
  );
});

class AssignmentRepository {
  final AssignmentRemoteDatasource remote;
  final AuthLocalDatasource local;

  AssignmentRepository({required this.remote, required this.local});

  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    final token = await local.getToken();
    if (token == null) throw Exception('Not logged in');
    return remote.getMyAssignments(token);
  }
}
