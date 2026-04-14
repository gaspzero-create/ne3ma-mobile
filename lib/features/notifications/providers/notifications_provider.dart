import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/features/notifications/data/model/notification_model.dart';


// ─── State ───────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get isEmpty => notifications.isEmpty;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  /// Call this when the screen loads — wire to your GraphQL client later
  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: replace with real GraphQL call
      // final result = await graphqlClient.query(NotificationQueries.myNotifications);
      // final list = (result['myNotifications'] as List)
      //     .map((e) => NotificationModel.fromJson(e))
      //     .toList();

      // Mock data — remove once backend is ready
      await Future.delayed(const Duration(milliseconds: 600));
      final list = <NotificationModel>[];

      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);

    // TODO: GraphQL mutation
    // await graphqlClient.mutate(NotificationQueries.markAsRead, {'id': id});
  }

  Future<void> markAllAsRead() async {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);

    // TODO: GraphQL mutation
    // await graphqlClient.mutate(NotificationQueries.markAllAsRead);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(),
);

/// Convenience: just the unread count for the badge
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
