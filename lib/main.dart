import 'package:flutter/material.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase.memory();

  runApp(MindCashApp(database: database));
}
