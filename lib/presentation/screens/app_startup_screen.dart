import 'package:flutter/material.dart';
import 'package:mindcash_app/data/repositories/account_repository.dart';
import 'package:mindcash_app/data/repositories/app_settings_repository.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/repositories/recurrence_repository.dart';
import 'package:mindcash_app/data/seeders/default_account_seeder.dart';
import 'package:mindcash_app/data/seeders/default_category_seeder.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/screens/app_shell.dart';
import 'package:mindcash_app/presentation/screens/onboarding_screen.dart';
import 'package:mindcash_app/presentation/widgets/error_state.dart';
import 'package:mindcash_app/presentation/widgets/loading_state.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  Future<bool>? _startupFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startupFuture ??= _prepareStartup();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: ErrorState(
                title: 'Não foi possível iniciar o MindCash',
                message: 'Confira os dados locais e tente novamente.',
                onRetry: () {
                  setState(() {
                    _startupFuture = _prepareStartup();
                  });
                },
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: SafeArea(
              child: LoadingState(message: 'Preparando o MindCash...'),
            ),
          );
        }

        if (snapshot.data!) {
          return const AppShell();
        }

        return OnboardingScreen(
          onCompleted: () {
            setState(() {
              _startupFuture = _prepareStartup();
            });
          },
        );
      },
    );
  }

  Future<bool> _prepareStartup() async {
    final database = AppDependencies.databaseOf(context);
    final settings = await AppSettingsRepository(database).getSettings();

    if (!settings.hasCompletedOnboarding) {
      return false;
    }

    await DefaultAccountSeeder(AccountRepository(database)).seed();
    await DefaultCategorySeeder(CategoryRepository(database)).seed();
    await RecurrenceRepository(database).executePendingRecurrences();

    return true;
  }
}
