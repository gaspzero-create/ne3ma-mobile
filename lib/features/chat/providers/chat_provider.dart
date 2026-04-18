import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../services/chat_socket_service.dart';

// ── Backend URL ────────────────────────────────────────
const String _backendUrl =
    'https://ne3ma-backend-production-0f70.up.railway.app';
const String _mineMessageIdsKeyPrefix = 'chat_mine_message_ids';

// ── Repository provider ────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// ── Chat State ─────────────────────────────────────────
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isConnected;
  final bool isSending;
  final String? error;
  final String? currentRoomId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.isSending = false,
    this.error,
    this.currentRoomId,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isConnected,
    bool? isSending,
    String? error,
    String? currentRoomId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      error: error,
      currentRoomId: currentRoomId ?? this.currentRoomId,
    );
  }
}

// ── Chat Notifier ──────────────────────────────────────
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatRepository _repository;
  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _errorSub;

  ChatNotifier(this._ref, this._repository) : super(const ChatState());

  // ── Initialize chat for a reservation ─────────
  Future<void> initChat(String reservationId) async {
    debugPrint('📤 ChatProvider: Initializing chat for room $reservationId');
    final currentUserId = _ref.read(currentUserProvider)?.id;
    final knownMineIds = currentUserId == null
        ? <String>{}
        : await _loadKnownMineMessageIds(currentUserId, reservationId);

    // If already in this room → skip
    if (state.currentRoomId == reservationId && state.isConnected) {
      debugPrint('⚡ ChatProvider: Already in room $reservationId');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      currentRoomId: reservationId,
      messages: [],
      error: null,
    );

    try {
      // ── 1. Load history from GraphQL ──────────
      final history = await _repository.getChatHistory(
        reservationId,
        currentUserId: currentUserId,
        knownMineIds: knownMineIds,
      );
      debugPrint('✅ ChatProvider: Loaded ${history.length} history messages');
      state = state.copyWith(messages: history, isLoading: false);

      // ── 2. Connect socket ─────────────────────
      await _connectSocket(reservationId, currentUserId: currentUserId);
    } catch (e) {
      debugPrint('❌ ChatProvider: Init error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Connect socket + join room ─────────────────
  Future<void> _connectSocket(
    String reservationId, {
    String? currentUserId,
  }) async {
    debugPrint('⚡ ChatProvider: Connecting socket...');

    // Get token
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      debugPrint('❌ ChatProvider: No token found');
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    // Cancel old subscriptions
    await _messageSub?.cancel();
    await _connectionSub?.cancel();
    await _errorSub?.cancel();

    final socket = ChatSocketService.instance;

    // ── Listen for connection status ───────────
    _connectionSub = socket.onConnection.listen((connected) {
      debugPrint('⚡ ChatProvider: Connection status = $connected');
      state = state.copyWith(
        isConnected: connected,
        error: connected ? null : state.error,
      );

      // When connected → join room
      if (connected) {
        socket.joinRoom(reservationId);
      }
    });

    // ── Listen for new messages ────────────────
    _messageSub = socket.onNewMessage.listen((data) {
      debugPrint('📨 ChatProvider: New message - $data');

      final newMsg = ChatMessageModel.fromSocket(
        data,
        currentUserId: currentUserId,
      );

      if (newMsg.isMine &&
          currentUserId != null &&
          state.currentRoomId != null) {
        unawaited(
          _rememberMineMessageId(
            currentUserId,
            state.currentRoomId!,
            newMsg.id,
          ),
        );
      }

      final msgs = [...state.messages];
      final existingIdx = msgs.indexWhere((m) => m.id == newMsg.id);

      if (existingIdx != -1) {
        msgs[existingIdx] = newMsg;
      } else {
        final optimisticIdx = msgs.indexWhere(
          (m) => m.isOptimistic && m.content == newMsg.content,
        );

        if (optimisticIdx != -1) {
          msgs[optimisticIdx] = newMsg;
        } else {
          msgs.add(newMsg);
        }
      }

      state = state.copyWith(messages: msgs, isSending: false, error: null);
    });

    _errorSub = socket.onError.listen((message) {
      debugPrint('❌ ChatProvider: Socket error - $message');
      final messages = [...state.messages];
      if (state.isSending) {
        final optimisticIndex = messages.lastIndexWhere(
          (item) => item.isOptimistic,
        );
        if (optimisticIndex != -1) {
          messages.removeAt(optimisticIndex);
        }
      }
      state = state.copyWith(
        isSending: false,
        error: message,
        messages: messages,
      );
    });

    if (socket.isConnected) {
      debugPrint('⚡ ChatProvider: Reusing existing socket connection');
      state = state.copyWith(isConnected: true);
      socket.joinRoom(reservationId);
      return;
    }

    socket.connect(baseUrl: _backendUrl, token: token);
  }

  // ── Send a message ─────────────────────────────
  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    if (state.currentRoomId == null) return;
    if (!state.isConnected) {
      state = state.copyWith(error: 'Chat is still connecting');
      return;
    }

    debugPrint('📤 ChatProvider: Sending "$content"');

    final optimistic = ChatMessageModel.optimistic(content: content.trim());
    state = state.copyWith(
      isSending: true,
      error: null,
      messages: [...state.messages, optimistic],
    );

    // ── Emit via socket ────────────────────────
    ChatSocketService.instance.sendMessage(
      reservationId: state.currentRoomId!,
      content: content.trim(),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _mineMessageIdsKey(String userId, String roomId) {
    return '$_mineMessageIdsKeyPrefix:$userId:$roomId';
  }

  Future<Set<String>> _loadKnownMineMessageIds(
    String userId,
    String roomId,
  ) async {
    const storage = FlutterSecureStorage();
    final raw = await storage.read(key: _mineMessageIdsKey(userId, roomId));

    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toSet();
      }
    } catch (e) {
      debugPrint('❌ ChatProvider: Failed to read mine message cache - $e');
    }

    return <String>{};
  }

  Future<void> _rememberMineMessageId(
    String userId,
    String roomId,
    String messageId,
  ) async {
    if (messageId.isEmpty || messageId.startsWith('optimistic_')) {
      return;
    }

    const storage = FlutterSecureStorage();
    final ids = await _loadKnownMineMessageIds(userId, roomId);
    if (!ids.add(messageId)) {
      return;
    }

    await storage.write(
      key: _mineMessageIdsKey(userId, roomId),
      value: jsonEncode(ids.toList()),
    );
  }

  // ── Dispose chat ────────────────────────────────
  @override
  void dispose() {
    debugPrint('🗑️ ChatProvider: Disposing...');
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _errorSub?.cancel();
    ChatSocketService.instance.disconnect();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────
final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (ref) {
    return ChatNotifier(ref, ref.read(chatRepositoryProvider));
  },
);
