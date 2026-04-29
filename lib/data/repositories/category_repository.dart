import 'package:drift/drift.dart';
import 'package:mindcash_app/data/database/app_database.dart';

class CategoryRepository {
  const CategoryRepository(this._database);

  final AppDatabase _database;

  Future<Category> createCategory({
    required String name,
    required String type,
    int? colorValue,
    String? iconName,
    bool isSystem = false,
  }) async {
    final now = DateTime.now();
    final id = await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            uuid: _createUuid(now),
            name: name.trim(),
            type: type,
            colorValue: Value.absentIfNull(colorValue),
            iconName: Value.absentIfNull(iconName?.trim()),
            isSystem: Value(isSystem),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return getById(id);
  }

  Future<Category> getById(int id) {
    return (_database.select(
      _database.categories,
    )..where((category) => category.id.equals(id))).getSingle();
  }

  Future<List<Category>> listActiveCategories({String? type}) {
    return (_database.select(_database.categories)
          ..where(
            (category) =>
                category.isActive.equals(true) & category.deletedAt.isNull(),
          )
          ..where((category) {
            if (type == null) {
              return const Constant(true);
            }

            return category.type.equals(type);
          })
          ..orderBy([(category) => OrderingTerm.asc(category.name)]))
        .get();
  }

  Future<void> updateCategory(Category category) {
    return (_database.update(
      _database.categories,
    )..where((row) => row.id.equals(category.id))).write(
      category
          .copyWith(name: category.name.trim(), updatedAt: DateTime.now())
          .toCompanion(false),
    );
  }

  Future<void> deactivateCategory(int id) {
    final now = DateTime.now();

    return (_database.update(
      _database.categories,
    )..where((category) => category.id.equals(id))).write(
      CategoriesCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        deletedAt: Value(now),
      ),
    );
  }

  String _createUuid(DateTime now) {
    return 'category-${now.microsecondsSinceEpoch}';
  }
}
