import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hamropadhai/app/app.dart';
import 'package:hamropadhai/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:hamropadhai/features/dashboard/presentation/services/notification_service.dart';
import 'package:hamropadhai/core/api/api_endpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox(AuthLocalDatasource.userBoxName);

  await Firebase.initializeApp();

  await ApiEndpoints.init();

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: App()));
}
