import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DonationFilterBar extends StatelessWidget {
  const DonationFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  final String? selectedCategory;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            emoji: '🍽️',
            isSelected: selectedCategory == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Fresh',
            emoji: '🥬',
            isSelected: selectedCategory == 'FRESH',
            onTap: () => onSelect('FRESH'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Dry',
            emoji: '🌾',
            isSelected: selectedCategory == 'DRY',
            onTap: () => onSelect('DRY'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Urgent',
            emoji: '🔴',
            isSelected: selectedCategory == 'URGENT',
            onTap: () => onSelect('URGENT'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
