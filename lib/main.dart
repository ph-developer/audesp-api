import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_env.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();

  final db = openConnection();
  await db.initialize();
  await db.close();

  runApp(const ProviderScope(child: App()));
}

