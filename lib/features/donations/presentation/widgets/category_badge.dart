import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(String category) {
    switch (category) {
      case 'FRESH':
        return _BadgeConfig(
          label: 'Fresh',
          emoji: '🥬',
          color: AppColors.primary,
          bg: AppColors.primarySurface,
        );
      case 'URGENT':
        return _BadgeConfig(
          label: 'Urgent',
          emoji: '🔴',
          color: AppColors.error,
          bg: AppColors.errorSurface,
        );
      case 'DRY':
      default:
        return _BadgeConfig(
          label: 'Dry',
          emoji: '🌾',
          color: AppColors.accent,
          bg: AppColors.accentSurface,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final String emoji;
  final Color color;
  final Color bg;
  const _BadgeConfig({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bg,
  });
}
