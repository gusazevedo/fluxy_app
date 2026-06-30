import 'categories_strings.dart';

/// Returns a pt-BR error message, or null when the name is valid (1–60 trimmed).
String? categoryNameError(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return CategoriesStrings.nameRequired;
  if (name.length > 60) return CategoriesStrings.nameTooLong;
  return null;
}
