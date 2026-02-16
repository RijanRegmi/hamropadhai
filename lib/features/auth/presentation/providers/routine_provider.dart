import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/remote/routine_remote_datasource.dart';
import 'auth_token_provider.dart';

final routineProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final token = await ref.watch(authTokenProvider.future);
  if (token == null) throw Exception('Not logged in');
  final remote = RoutineRemoteDatasource(http.Client());
  return remote.getMyRoutine(token);
});
