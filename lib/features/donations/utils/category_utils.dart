String normalizeCategoryName(String? value) {
  return value
      ?.trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ') ??
      '';
}

String displayCategoryLabel(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Other';

  return trimmed
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

bool isUrgentCategory(String? value) {
  final normalized = normalizeCategoryName(value);
  return normalized.contains('urgent') ||
      normalized.contains('emergency') ||
      normalized.contains('priority') ||
      normalized.contains('expiring');
}

bool isFreshCategory(String? value) {
  final normalized = normalizeCategoryName(value);
  return normalized.contains('fresh') ||
      normalized.contains('fruit') ||
      normalized.contains('vegetable') ||
      normalized.contains('veggie') ||
      normalized.contains('produce') ||
      normalized.contains('salad') ||
      normalized.contains('dairy') ||
      normalized.contains('bakery');
}

bool isDryCategory(String? value) {
  final normalized = normalizeCategoryName(value);
  return normalized.contains('dry') ||
      normalized.contains('grain') ||
      normalized.contains('rice') ||
      normalized.contains('pasta') ||
      normalized.contains('flour') ||
      normalized.contains('cereal') ||
      normalized.contains('bean') ||
      normalized.contains('lentil');
}

bool matchesStoredCategory({
  required String storedValue,
  required String categoryId,
  required String categoryName,
}) {
  final normalizedStored = normalizeCategoryName(storedValue);
  final normalizedName = normalizeCategoryName(categoryName);

  if (storedValue == categoryId) return true;
  if (normalizedStored == normalizedName) return true;
  if (normalizedStored == 'fresh' && isFreshCategory(categoryName)) return true;
  if (normalizedStored == 'urgent' && isUrgentCategory(categoryName)) {
    return true;
  }
  if (normalizedStored == 'dry' && isDryCategory(categoryName)) return true;
  return false;
}
