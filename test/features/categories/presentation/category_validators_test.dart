import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/category_validators.dart';

void main() {
  test('rejects empty / whitespace-only names', () {
    expect(categoryNameError(''), CategoriesStrings.nameRequired);
    expect(categoryNameError('   '), CategoriesStrings.nameRequired);
  });

  test('rejects names longer than 60 chars (after trim)', () {
    expect(categoryNameError('a' * 61), CategoriesStrings.nameTooLong);
  });

  test('accepts a valid trimmed name', () {
    expect(categoryNameError('  Mercado  '), null);
    expect(categoryNameError('a' * 60), null);
  });
}
