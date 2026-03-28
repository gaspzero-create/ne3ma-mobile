import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/messages');
        break;
      case 2:
        context.go('/add');
        break;
      case 3:
        context.go('/special');
        break;
      case 4:
        context.go('/profile-tab');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            // ── Home ──────────────────────────────
            _buildNavItem(
              context: context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),

            // ── Messages ──────────────────────────
            _buildNavItem(
              context: context,
              index: 1,
              icon: Icons.mail_outline_rounded,
              activeIcon: Icons.mail_rounded,
              label: 'Messages',
              badgeDot: true,
            ),

            // ── Add (center button) ───────────────
            _buildAddButton(context),

            // ── Special ───────────────────────────
            _buildNavItem(
              context: context,
              index: 3,
              icon: Icons.favorite_border_rounded,
              activeIcon: Icons.favorite_rounded,
              label: 'Special',
              badgeCount: 2,
            ),

            // ── Profile ───────────────────────────
            _buildNavItem(
              context: context,
              index: 4,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ── Regular Nav Item ───────────────────────────
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool badgeDot = false,
    int? badgeCount,
  }) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon with badge ──────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 26,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),

                // ── Red dot badge ────────────────
                if (badgeDot)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // ── Count badge ──────────────────
                if (badgeCount != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Label ────────────────────────────
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Center Add Button ──────────────────────────
Widget _buildAddButton(BuildContext context) {
  final bool isActive = currentIndex == 2;

  return GestureDetector(
    onTap: () => _onTap(context, 2),
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Outlined circle + ─────────────────
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
                width: 1.8,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Add',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
}