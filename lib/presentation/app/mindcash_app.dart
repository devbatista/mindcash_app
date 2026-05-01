import 'package:flutter/material.dart';
import 'package:mindcash_app/core/theme/app_theme.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/screens/app_startup_screen.dart';

class MindCashApp extends StatelessWidget {
  const MindCashApp({required this.database, super.key});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      database: database,
      child: MaterialApp(
        title: 'MindCash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppStartupScreen(),
      ),
    );
  }
}
