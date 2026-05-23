import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/features/chat/services/chat_socket_service.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

final messagesBadgeProvider =
    StateNotifierProvider<MessagesBadgeNotifier, MessagesBadgeState>((ref) {
      final notifier = MessagesBadgeNotifier(ref);
      notifier.init();
      return notifier;
    });

class MessagesBadgeState {
  final bool hasUnread;
  final Set<String> unreadConversationIds;

  const MessagesBadgeState({
    this.hasUnread = false,
    this.unreadConversationIds = const <String>{},
  });

  MessagesBadgeState copyWith({
    bool? hasUnread,
    Set<String>? unreadConversationIds,
  }) {
    return MessagesBadgeState(
      hasUnread: hasUnread ?? this.hasUnread,
      unreadConversationIds:
          unreadConversationIds ?? this.unreadConversationIds,
    );
  }
}

class MessagesBadgeNotifier extends StateNotifier<MessagesBadgeState> {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();
  final ChatSocketService _socket = ChatSocketService.detached();
  static const _lastOpenedKey = 'last_opened_messages_tab';
  static const _unreadRoomsKey = 'unread_message_room_ids';
  DateTime? _lastOpenedAt;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<bool>? _connectionSub;
  final Set<String> _trackedRoomIds = <String>{};
  final Set<String> _joinedRoomIds = <String>{};
  bool _socketInitialized = false;
  bool _hasReservationUnread = false;
  final Set<String> _unreadConversationIds = <String>{};

  MessagesBadgeNotifier(this._ref) : super(const MessagesBadgeState()) {
    _ref.listen(donationsProvider, (previous, next) {
      _checkUnreadStatus(next);
      unawaited(_syncTrackedRooms(next));
    });
  }

  Future<void> init() async {
    final storedStr = await _storage.read(key: _lastOpenedKey);
    if (storedStr != null && storedStr.isNotEmpty) {
      _lastOpenedAt = DateTime.tryParse(storedStr);
    }
    final storedUnreadRooms = await _storage.read(key: _unreadRoomsKey);
    if (storedUnreadRooms != null && storedUnreadRooms.isNotEmpty) {
      final parsed = storedUnreadRooms
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty);
      _unreadConversationIds.addAll(parsed);
    }
    _checkUnreadStatus(_ref.read(donationsProvider));
    await _syncTrackedRooms(_ref.read(donationsProvider));
  }

  void _checkUnreadStatus(DonationsState donationsState) {
    bool hasNewUnread = false;

    final allConfirmed = [
      ...donationsState.myDonationReservations.where(
        (r) => r.status == 'CONFIRMED',
      ),
      ...donationsState.myReservations.where((r) => r.status == 'CONFIRMED'),
    ];

    if (_lastOpenedAt == null && allConfirmed.isNotEmpty) {
      hasNewUnread = true;
    } else if (_lastOpenedAt != null) {
      for (var r in allConfirmed) {
        final dateStr = r.updatedAt ?? r.confirmedAt ?? r.reservedAt;
        final date = DateTime.tryParse(dateStr)?.toLocal();
        if (date != null && date.isAfter(_lastOpenedAt!)) {
          hasNewUnread = true;
          break;
        }
      }
    }

    _hasReservationUnread = hasNewUnread;
    _updateBadgeState();
  }

  Future<void> _syncTrackedRooms(DonationsState donationsState) async {
    final nextRoomIds = <String>{
      ...donationsState.myDonationReservations
          .where((r) => r.status == 'CONFIRMED')
          .map((r) => r.id),
      ...donationsState.myReservations
          .where((r) => r.status == 'CONFIRMED')
          .map((r) => r.id),
    }.where((roomId) => roomId.trim().isNotEmpty).toSet();

    _trackedRoomIds
      ..clear()
      ..addAll(nextRoomIds);
    _joinedRoomIds.removeWhere((roomId) => !_trackedRoomIds.contains(roomId));

    if (_trackedRoomIds.isEmpty) {
      return;
    }

    await _ensureSocketConnected();
    _joinTrackedRooms();
  }

  Future<void> _ensureSocketConnected() async {
    if (_socketInitialized) {
      if (_socket.isConnected) {
        _joinTrackedRooms();
      }
      return;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ MessagesBadge: No access token, skip socket badge sync');
      return;
    }

    _socketInitialized = true;

    _connectionSub = _socket.onConnection.listen((connected) {
      if (!connected) return;
      _joinedRoomIds.clear();
      _joinTrackedRooms();
    });

    _messageSub = _socket.onNewMessage.listen((payload) {
      final roomId = payload['roomId']?.toString();
      final senderId = payload['senderId']?.toString();
      final currentUserId = _ref.read(currentUserProvider)?.id;

      if (roomId == null || !_trackedRoomIds.contains(roomId)) {
        return;
      }

      if (currentUserId != null && senderId == currentUserId) {
        return;
      }

      _unreadConversationIds.add(roomId);
      unawaited(_persistUnreadConversationIds());
      debugPrint('🔴 MessagesBadge: New incoming message in room $roomId');
      _updateBadgeState();
    });

    if (_socket.isConnected) {
      _joinTrackedRooms();
      return;
    }

    _socket.connect(baseUrl: GraphQLClient.backendBaseUrl, token: token);
  }

  void _joinTrackedRooms() {
    if (!_socket.isConnected) return;

    for (final roomId in _trackedRoomIds) {
      if (_joinedRoomIds.contains(roomId)) continue;
      _socket.joinRoom(roomId);
      _joinedRoomIds.add(roomId);
    }
  }

  Future<void> markAsRead() async {
    _lastOpenedAt = DateTime.now();
    await _storage.write(
      key: _lastOpenedKey,
      value: _lastOpenedAt!.toIso8601String(),
    );
    _hasReservationUnread = false;
    _updateBadgeState();
    debugPrint('✅ MessagesBadge: marked as read at $_lastOpenedAt');
  }

  Future<void> markConversationAsRead(String roomId) async {
    if (_unreadConversationIds.remove(roomId)) {
      await _persistUnreadConversationIds();
      _updateBadgeState();
    }
  }

  void _updateBadgeState() {
    final hasUnread =
        _hasReservationUnread || _unreadConversationIds.isNotEmpty;
    if (hasUnread == state.hasUnread &&
        _sameUnreadIds(state.unreadConversationIds, _unreadConversationIds)) {
      return;
    }
    debugPrint('🔔 MessagesBadge: hasUnread=$hasUnread');
    state = MessagesBadgeState(
      hasUnread: hasUnread,
      unreadConversationIds: Set<String>.from(_unreadConversationIds),
    );
  }

  Future<void> _persistUnreadConversationIds() {
    return _storage.write(
      key: _unreadRoomsKey,
      value: _unreadConversationIds.join(','),
    );
  }

  bool _sameUnreadIds(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket.disconnect();
    super.dispose();
  }
}
