import 'package:flutter/material.dart';
import 'package:mindcash_app/core/theme/app_theme.dart';
import 'package:mindcash_app/presentation/screens/app_shell.dart';

class MindCashApp extends StatelessWidget {
  const MindCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
