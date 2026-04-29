import 'package:mindcash_app/data/repositories/category_repository.dart';

class DefaultCategorySeeder {
  const DefaultCategorySeeder(this._categoryRepository);

  final CategoryRepository _categoryRepository;

  Future<void> seed() async {
    final existingCategories = await _categoryRepository.listActiveCategories();

    if (existingCategories.isNotEmpty) {
      return;
    }

    for (final category in _defaultCategories) {
      await _categoryRepository.createCategory(
        name: category.name,
        type: category.type,
        colorValue: category.colorValue,
        iconName: category.iconName,
        isSystem: true,
      );
    }
  }
}

const _defaultCategories = [
  _DefaultCategory(
    name: 'Salário',
    type: 'income',
    colorValue: 0xFF43A047,
    iconName: 'payments',
  ),
  _DefaultCategory(
    name: 'Renda extra',
    type: 'income',
    colorValue: 0xFF2E7D32,
    iconName: 'add_card',
  ),
  _DefaultCategory(
    name: 'Mercado',
    type: 'expense',
    colorValue: 0xFF3563D8,
    iconName: 'shopping_cart',
  ),
  _DefaultCategory(
    name: 'Alimentação',
    type: 'expense',
    colorValue: 0xFFF27A3D,
    iconName: 'restaurant',
  ),
  _DefaultCategory(
    name: 'Transporte',
    type: 'expense',
    colorValue: 0xFF54BF57,
    iconName: 'directions_car',
  ),
  _DefaultCategory(
    name: 'Saúde',
    type: 'expense',
    colorValue: 0xFF5B45B8,
    iconName: 'medical_services',
  ),
  _DefaultCategory(
    name: 'Moradia',
    type: 'expense',
    colorValue: 0xFFEF4444,
    iconName: 'home',
  ),
  _DefaultCategory(
    name: 'Outros',
    type: 'expense',
    colorValue: 0xFF9CA3AF,
    iconName: 'more_horiz',
  ),
];

class _DefaultCategory {
  const _DefaultCategory({
    required this.name,
    required this.type,
    required this.colorValue,
    required this.iconName,
  });

  final String name;
  final String type;
  final int colorValue;
  final String iconName;
}
