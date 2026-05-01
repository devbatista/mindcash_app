import 'package:flutter/material.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase.defaults();

  runApp(MindCashApp(database: database));
}
