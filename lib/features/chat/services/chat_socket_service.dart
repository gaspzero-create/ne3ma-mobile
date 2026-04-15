import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  ChatSocketService._internal();
  static final ChatSocketService instance = ChatSocketService._internal();

  ChatSocketService.detached() : this._internal();

  io.Socket? _socket;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // ── Public streams ─────────────────────────────
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<bool> get onConnection => _connectionController.stream;
  Stream<String> get onError => _errorController.stream;
  bool get isConnected => _socket?.connected ?? false;

  // ── Connect to socket ──────────────────────────
  void connect({
    required String baseUrl,
    required String token,
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('⚡ ChatSocket: Already connected');
      _connectionController.add(true);
      return;
    }

    if (_socket != null) {
      disconnect();
    }

    debugPrint('⚡ ChatSocket: Connecting to $baseUrl/chat...');

    _socket = io.io(
      '$baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
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
      _errorController.add(_normalizeError(err));
    });

    // ── Listen for new messages ────────────────
    _socket!.on('newMessage', (data) {
      debugPrint('📨 ChatSocket: New message received - $data');
      final mapped = _normalizeMap(data);
      if (mapped != null) {
        _messageController.add(mapped);
      }
    });

    // ── Room joined confirmation ───────────────
    _socket!.on('joinedRoom', (data) {
      debugPrint('✅ ChatSocket: Joined room - $data');
    });

    // ── Error handling ─────────────────────────
    _socket!.on('exception', (error) {
      final message = _normalizeError(error);
      debugPrint('❌ ChatSocket: Exception - $message');
      _errorController.add(message);
    });

    _socket!.connect();
  }

  // ── Join a room (reservation ID) ──────────────
  void joinRoom(String reservationId) {
    if (!isConnected) {
      debugPrint('❌ ChatSocket: Cannot join room - not connected');
      _errorController.add('Chat is still connecting');
      return;
    }
    debugPrint('📤 ChatSocket: Joining room $reservationId...');
    _socket!.emitWithAck(
      'joinRoom',
      {'roomId': reservationId},
      ack: (data) => debugPrint('✅ ChatSocket: joinRoom ack - $data'),
    );
  }

  // ── Send a message ─────────────────────────────
  void sendMessage({
    required String reservationId,
    required String content,
  }) {
    if (!isConnected) {
      debugPrint('❌ ChatSocket: Cannot send - not connected');
      _errorController.add('Chat is still connecting');
      return;
    }
    debugPrint('📤 ChatSocket: Sending message to room $reservationId...');
    _socket!.emitWithAck(
      'sendMessage',
      {
        'roomId': reservationId,
        'content': content,
      },
      ack: (data) => debugPrint('✅ ChatSocket: sendMessage ack - $data'),
    );
  }

  // ── Disconnect ─────────────────────────────────
  void disconnect() {
    debugPrint('⚡ ChatSocket: Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  // ── Dispose ────────────────────────────────────
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _errorController.close();
  }

  Map<String, dynamic>? _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  String _normalizeError(dynamic error) {
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    if (error is List && error.isNotEmpty) {
      return _normalizeError(error.first);
    }

    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message != null) {
        return message.toString();
      }
    }

    if (error is Map) {
      final mapped = Map<String, dynamic>.from(error);
      final message = mapped['message'];
      if (message != null) {
        return message.toString();
      }
    }

    return 'Chat connection error';
  }
}
