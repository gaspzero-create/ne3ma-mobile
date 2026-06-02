import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../data/model/notification_model.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch on open
    Future.microtask(
      () => ref.read(notificationsProvider.notifier).fetchNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text(
                'Mark all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryMid),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).fetchNotifications(),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primaryMid,
      onRefresh: () =>
          ref.read(notificationsProvider.notifier).fetchNotifications(),
      child: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () async {
              if (!notification.isRead) {
                await ref
                    .read(notificationsProvider.notifier)
                    .markAsRead(notification.id);
              }
              if (!context.mounted) return;
              await _openNotification(notification);
            },
          );
        },
      ),
    );
  }

  Future<void> _openNotification(NotificationModel notification) async {
    switch (notification.type) {
      case NotificationType.message:
        context.go('/messages');
        return;
      case NotificationType.warning:
        context.go('/profile-tab');
        return;
      case NotificationType.foodSaverHelpRequest:
      case NotificationType.foodSaverHelpResponse:
        final requestId = notification.foodSaverHelpRequestId;
        if (requestId != null && requestId.isNotEmpty) {
          context.push('/food-saver-help/$requestId');
        } else {
          context.go('/food-saver-help');
        }
        return;
      case NotificationType.reservation:
      case NotificationType.cancellation:
      case NotificationType.completion:
      case NotificationType.nearbyDonation:
        final donationId = notification.donationId;
        if (donationId != null && donationId.isNotEmpty) {
          try {
            final donation = await ref
                .read(donationRepositoryProvider)
                .getDonation(donationId);
            if (!mounted) return;
            if (donation != null) {
              context.push('/donation/${donation.id}', extra: donation);
              return;
            }
          } catch (_) {
            // Fall back to section routing below if donation lookup fails.
          }
        }

        if (!mounted) return;
        if (notification.type == NotificationType.nearbyDonation) {
          context.go('/home');
        } else {
          context.go('/special');
        }
        return;
      case NotificationType.unknown:
        return;
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No new notifications',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
