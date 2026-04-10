import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  IO.Socket?                          _socket;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // ── Public streams ─────────────────────────────
  Stream<Map<String, dynamic>> get onNewMessage  => _messageController.stream;
  Stream<bool>                 get onConnection  => _connectionController.stream;
  bool get isConnected => _socket?.connected ?? false;

  // ── Connect to socket ──────────────────────────
  void connect({
    required String baseUrl,
    required String token,
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('⚡ ChatSocket: Already connected');
      return;
    }

    debugPrint('⚡ ChatSocket: Connecting to $baseUrl/chat...');

    _socket = IO.io(
      '$baseUrl/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    // ── Connection events ──────────────────────
    _socket!.onConnect((_) {
      debugPrint('✅ ChatSocket: Connected!');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('⚠️ ChatSocket: Disconnected');
      _connectionController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ ChatSocket: Connect error - $err');
      _connectionController.add(false);
    });

    // ── Listen for new messages ────────────────
    _socket!.on('newMessage', (data) {
      debugPrint('📨 ChatSocket: New message received - $data');
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // ── Room joined confirmation ───────────────
    _socket!.on('joinedRoom', (data) {
      debugPrint('✅ ChatSocket: Joined room - $data');
    });

    // ── Error handling ─────────────────────────
    _socket!.on('exception', (error) {
      debugPrint('❌ ChatSocket: Exception - $error');
    });

    _socket!.connect();
  }

  // ── Join a room (reservation ID) ──────────────
  void joinRoom(String reservationId) {
    if (!isConnected) {
      debugPrint('❌ ChatSocket: Cannot join room - not connected');
      return;
    }
    debugPrint('📤 ChatSocket: Joining room $reservationId...');
    _socket!.emit('joinRoom', {'roomId': reservationId});
  }

  // ── Send a message ─────────────────────────────
  void sendMessage({
    required String reservationId,
    required String content,
  }) {
    if (!isConnected) {
      debugPrint('❌ ChatSocket: Cannot send - not connected');
      return;
    }
    debugPrint('📤 ChatSocket: Sending message to room $reservationId...');
    _socket!.emit('sendMessage', {
      'roomId':  reservationId,
      'content': content,
    });
  }

  // ── Disconnect ─────────────────────────────────
  void disconnect() {
    debugPrint('⚡ ChatSocket: Disconnecting...');
    _socket?.disconnect();
    _socket = null;
  }

  // ── Dispose ────────────────────────────────────
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
