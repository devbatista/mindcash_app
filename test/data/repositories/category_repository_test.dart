import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = CategoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and lists active categories by type', () async {
    await repository.createCategory(
      name: 'Mercado',
      type: 'expense',
      colorValue: 0xFF3563D8,
      iconName: 'shopping_cart',
      isSystem: true,
    );
    await repository.createCategory(name: 'Salário', type: 'income');

    final expenseCategories = await repository.listActiveCategories(
      type: 'expense',
    );

    expect(expenseCategories, hasLength(1));
    expect(expenseCategories.single.name, 'Mercado');
    expect(expenseCategories.single.type, 'expense');
    expect(expenseCategories.single.isSystem, isTrue);
  });

  test('deactivates category without hard delete', () async {
    final category = await repository.createCategory(
      name: 'Transporte',
      type: 'expense',
    );

    await repository.deactivateCategory(category.id);

    final activeCategories = await repository.listActiveCategories();
    final storedCategory = await repository.getById(category.id);

    expect(activeCategories, isEmpty);
    expect(storedCategory.isActive, isFalse);
    expect(storedCategory.deletedAt, isNotNull);
  });
}
