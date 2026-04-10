import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/chat_message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../services/chat_socket_service.dart';

// ── Backend URL ────────────────────────────────────────
const String _backendUrl = 'https://ne3ma-prod-service-helo.up.railway.app';

// ── Repository provider ────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// ── Chat State ─────────────────────────────────────────
class ChatState {
  final List<ChatMessageModel> messages;
  final bool                   isLoading;
  final bool                   isConnected;
  final bool                   isSending;
  final String?                error;
  final String?                currentRoomId;

  const ChatState({
    this.messages      = const [],
    this.isLoading     = false,
    this.isConnected   = false,
    this.isSending     = false,
    this.error,
    this.currentRoomId,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool?                   isLoading,
    bool?                   isConnected,
    bool?                   isSending,
    String?                 error,
    String?                 currentRoomId,
  }) {
    return ChatState(
      messages:      messages      ?? this.messages,
      isLoading:     isLoading     ?? this.isLoading,
      isConnected:   isConnected   ?? this.isConnected,
      isSending:     isSending     ?? this.isSending,
      error:         error,
      currentRoomId: currentRoomId ?? this.currentRoomId,
    );
  }
}

// ── Chat Notifier ──────────────────────────────────────
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  StreamSubscription?  _messageSub;
  StreamSubscription?  _connectionSub;

  ChatNotifier(this._repository) : super(const ChatState());

  // ── Initialize chat for a reservation ─────────
  Future<void> initChat(String reservationId) async {
    debugPrint('📤 ChatProvider: Initializing chat for room $reservationId');

    // If already in this room → skip
    if (state.currentRoomId == reservationId && state.isConnected) {
      debugPrint('⚡ ChatProvider: Already in room $reservationId');
      return;
    }

    state = state.copyWith(
      isLoading:     true,
      currentRoomId: reservationId,
      messages:      [],
      error:         null,
    );

    try {
      // ── 1. Load history from GraphQL ──────────
      final history = await _repository.getChatHistory(reservationId);
      debugPrint('✅ ChatProvider: Loaded ${history.length} history messages');
      state = state.copyWith(messages: history, isLoading: false);

      // ── 2. Connect socket ─────────────────────
      await _connectSocket(reservationId);

    } catch (e) {
      debugPrint('❌ ChatProvider: Init error - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ── Connect socket + join room ─────────────────
  Future<void> _connectSocket(String reservationId) async {
    debugPrint('⚡ ChatProvider: Connecting socket...');

    // Get token
    const storage = FlutterSecureStorage();
    final token   = await storage.read(key: 'access_token');

    if (token == null) {
      debugPrint('❌ ChatProvider: No token found');
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    // Cancel old subscriptions
    await _messageSub?.cancel();
    await _connectionSub?.cancel();

    final socket = ChatSocketService.instance;

    // ── Listen for connection status ───────────
    _connectionSub = socket.onConnection.listen((connected) {
      debugPrint('⚡ ChatProvider: Connection status = $connected');
      state = state.copyWith(isConnected: connected);

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
        isMine: false, // server broadcasts to all — we don't know sender yet
      );

      // Replace optimistic message if exists, else add
      final msgs = [...state.messages];
      final optimisticIdx = msgs.indexWhere(
        (m) => m.isOptimistic && m.content == newMsg.content,
      );

      if (optimisticIdx != -1) {
        msgs[optimisticIdx] = newMsg;
      } else {
        msgs.add(newMsg);
      }

      state = state.copyWith(messages: msgs);
    });

    // Connect
    socket.connect(baseUrl: _backendUrl, token: token);
  }

  // ── Send a message ─────────────────────────────
  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    if (state.currentRoomId == null) return;

    debugPrint('📤 ChatProvider: Sending "$content"');

    // ── Optimistic update ──────────────────────
    final optimistic = ChatMessageModel.optimistic(content: content.trim());
    state = state.copyWith(
      messages: [...state.messages, optimistic],
    );

    // ── Emit via socket ────────────────────────
    ChatSocketService.instance.sendMessage(
      reservationId: state.currentRoomId!,
      content:       content.trim(),
    );
  }

  // ── Dispose chat ────────────────────────────────
  @override
  void dispose() {
    debugPrint('🗑️ ChatProvider: Disposing...');
    _messageSub?.cancel();
    _connectionSub?.cancel();
    ChatSocketService.instance.disconnect();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(chatRepositoryProvider));
});
