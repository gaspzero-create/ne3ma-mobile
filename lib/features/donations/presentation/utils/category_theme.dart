import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../utils/category_utils.dart';

class CategoryThemeData {
  final String label;
  final String emoji;
  final Color color;
  final Color background;

  const CategoryThemeData({
    required this.label,
    required this.emoji,
    required this.color,
    required this.background,
  });
}

CategoryThemeData categoryTheme(String? categoryName) {
  final label = displayCategoryLabel(categoryName);

  if (isUrgentCategory(categoryName)) {
    return CategoryThemeData(
      label: label,
      emoji: '⚡',
      color: AppColors.error,
      background: AppColors.errorSurface,
    );
  }

  if (isFreshCategory(categoryName)) {
    return CategoryThemeData(
      label: label,
      emoji: '🥗',
      color: AppColors.primary,
      background: AppColors.primarySurface,
    );
  }

  if (isDryCategory(categoryName)) {
    return CategoryThemeData(
      label: label,
      emoji: '🌾',
      color: AppColors.accent,
      background: AppColors.accentSurface,
    );
  }

  return CategoryThemeData(
    label: label,
    emoji: '🍽️',
    color: AppColors.accent,
    background: AppColors.accentSurface,
  );
}
