import 'package:flutter/material.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/notifications/data/model/notification_model.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primarySurface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (notification.userName != null &&
                      notification.userName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryMid,
                          backgroundImage:
                              notification.userAvatarUrl != null &&
                                  notification.userAvatarUrl!.isNotEmpty
                              ? NetworkImage(notification.userAvatarUrl!)
                              : null,
                          child:
                              notification.userAvatarUrl == null ||
                                  notification.userAvatarUrl!.isEmpty
                              ? Text(
                                  notification.userName![0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notification.userName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d';
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final config = _iconConfig(type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        color: config.foreground,
        size: 22,
      ),
    );
  }

  _NotificationIconConfig _iconConfig(NotificationType type) {
    switch (type) {
      case NotificationType.reservation:
        return const _NotificationIconConfig(
          icon: Icons.notifications_active_rounded,
          background: AppColors.primarySurface,
          foreground: AppColors.primary,
        );
      case NotificationType.cancellation:
        return const _NotificationIconConfig(
          icon: Icons.cancel_outlined,
          background: AppColors.errorSurface,
          foreground: AppColors.error,
        );
      case NotificationType.completion:
        return const _NotificationIconConfig(
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFE9F7EF),
          foreground: Color(0xFF2E7D32),
        );
      case NotificationType.warning:
        return const _NotificationIconConfig(
          icon: Icons.warning_amber_rounded,
          background: Color(0xFFFFF4E5),
          foreground: Color(0xFFF59E0B),
        );
      case NotificationType.message:
        return const _NotificationIconConfig(
          icon: Icons.chat_bubble_outline_rounded,
          background: AppColors.accentSurface,
          foreground: AppColors.accent,
        );
      case NotificationType.nearbyDonation:
        return const _NotificationIconConfig(
          icon: Icons.location_on_outlined,
          background: AppColors.surfaceVariant,
          foreground: AppColors.primary,
        );
      case NotificationType.unknown:
        return const _NotificationIconConfig(
          icon: Icons.notifications_none_rounded,
          background: AppColors.surfaceVariant,
          foreground: AppColors.textSecondary,
        );
    }
  }
}

class _NotificationIconConfig {
  const _NotificationIconConfig({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}
