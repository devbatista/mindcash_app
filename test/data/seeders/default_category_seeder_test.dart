import 'package:flutter_test/flutter_test.dart';
import 'package:mindcash_app/data/database/app_database.dart';
import 'package:mindcash_app/data/repositories/category_repository.dart';
import 'package:mindcash_app/data/seeders/default_category_seeder.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository categoryRepository;
  late DefaultCategorySeeder seeder;

  setUp(() {
    database = AppDatabase.memory();
    categoryRepository = CategoryRepository(database);
    seeder = DefaultCategorySeeder(categoryRepository);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates default income and expense categories', () async {
    await seeder.seed();

    final categories = await categoryRepository.listActiveCategories();
    final incomeCategories = await categoryRepository.listActiveCategories(
      type: 'income',
    );
    final expenseCategories = await categoryRepository.listActiveCategories(
      type: 'expense',
    );

    expect(categories, hasLength(8));
    expect(
      incomeCategories.map((category) => category.name),
      contains('Salário'),
    );
    expect(
      expenseCategories.map((category) => category.name),
      contains('Mercado'),
    );
    expect(categories.every((category) => category.isSystem), isTrue);
  });

  test('does not duplicate categories when seeded twice', () async {
    await seeder.seed();
    await seeder.seed();

    final categories = await categoryRepository.listActiveCategories();

    expect(categories, hasLength(8));
  });
}
