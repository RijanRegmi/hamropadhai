import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

final authTokenProvider = FutureProvider<String?>((ref) async {
  final local = AuthLocalDatasource();
  return await local.getToken();
});
