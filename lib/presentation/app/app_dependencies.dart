import 'package:flutter/widgets.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.database,
    required super.child,
    super.key,
  });

  final AppDatabase database;

  static AppDatabase databaseOf(BuildContext context) {
    final dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();

    assert(
      dependencies != null,
      'AppDependencies was not found above this context.',
    );

    return dependencies!.database;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return oldWidget.database != database;
  }
}
