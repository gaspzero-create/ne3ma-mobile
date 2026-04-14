import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notifications_provider.dart';
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: Colors.black, size: 28),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        // Mark all as read button — only shown when there are unread
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text(
                'Mark all',
                style: TextStyle(
                  color: Color(0xFF7FA668),
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
    // ── Loading ──
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7FA668)),
      );
    }

    // ── Error ──
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).fetchNotifications(),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF7FA668))),
            ),
          ],
        ),
      );
    }

    // ── Empty state ──
    if (state.isEmpty) {
      return const _EmptyState();
    }

    // ── Notification list ──
    return RefreshIndicator(
      color: const Color(0xFF7FA668),
      onRefresh: () =>
          ref.read(notificationsProvider.notifier).fetchNotifications(),
      child: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationsProvider.notifier)
                    .markAsRead(notification.id);
              }
              // TODO: navigate based on notification.type
            },
          );
        },
      ),
    );
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
            color: Colors.grey[350],
          ),
          const SizedBox(height: 16),
          Text(
            'No new notifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
