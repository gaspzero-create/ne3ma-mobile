import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/features/notifications/data/model/notification_model.dart';
import 'package:ne3ma/features/notifications/data/repository/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

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

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> fetchNotifications({bool background = false}) async {
    if (!background) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final list = await _repository.getMyNotifications();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        notifications: list,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: background ? state.error : e.toString(),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final existing = state.notifications;
    final updated = existing
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(notifications: updated);

    try {
      final success = await _repository.markNotificationAsRead(id);
      if (!success) {
        state = state.copyWith(notifications: existing);
      }
    } catch (e) {
      state = state.copyWith(
        notifications: existing,
        error: e.toString(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = state.notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) return;

    final previous = state.notifications;
    state = state.copyWith(
      notifications: previous.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      for (final id in unreadIds) {
        await _repository.markNotificationAsRead(id);
      }
    } catch (e) {
      state = state.copyWith(
        notifications: previous,
        error: e.toString(),
      );
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier(ref.read(notificationRepositoryProvider));
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
