import 'package:flutter/material.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/seeders/default_account_seeder.dart';
import 'package:mindcash_app/data/seeders/default_category_seeder.dart';
import 'package:mindcash_app/presentation/app/mindcash_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase.defaults();
  await _seedDefaultData(database);
  await RecurrenceRepository(database).executePendingRecurrences();

  runApp(MindCashApp(database: database));
}

Future<void> _seedDefaultData(AppDatabase database) async {
  await DefaultAccountSeeder(AccountRepository(database)).seed();
  await DefaultCategorySeeder(CategoryRepository(database)).seed();
}
