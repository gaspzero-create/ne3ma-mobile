class ChatMessageModel {
  final String id;
  final String? roomId;
  final String? senderId;
  final String content;
  final bool   isModerated;
  final String sentAt;

  // ── UI helpers (not from backend) ─────────────
  final bool   isMine;   // set locally based on current user

  const ChatMessageModel({
    required this.id,
    this.roomId,
    this.senderId,
    required this.content,
    required this.isModerated,
    required this.sentAt,
    this.isMine = false,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map, {
    String? currentUserId,
    Set<String>? knownMineIds,
  }) {
    final senderId = map['senderId']?.toString();
    final messageId = map['id']?.toString() ?? '';
    return ChatMessageModel(
      id:          messageId,
      roomId:      map['roomId']?.toString(),
      senderId:    senderId,
      content:     map['content']     ?? '',
      isModerated: map['isModerated'] ?? false,
      sentAt:      map['sentAt']      ?? '',
      isMine:      (currentUserId != null && senderId == currentUserId) ||
          (knownMineIds?.contains(messageId) ?? false),
    );
  }

  // ── For socket newMessage ──────────────────────
  factory ChatMessageModel.fromSocket(
    Map<String, dynamic> map, {
    String? currentUserId,
  }) {
    final senderId = map['senderId']?.toString();
    return ChatMessageModel(
      id:          map['id']          ?? DateTime.now().toString(),
      roomId:      map['roomId']?.toString(),
      senderId:    senderId,
      content:     map['content']     ?? '',
      isModerated: map['isModerated'] ?? false,
      sentAt:      map['sentAt']      ?? DateTime.now().toIso8601String(),
      isMine:      currentUserId != null && senderId == currentUserId,
    );
  }

  // ── Optimistic message (before server confirms) ─
  factory ChatMessageModel.optimistic({
    required String content,
  }) {
    return ChatMessageModel(
      id:          'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      roomId:      null,
      senderId:    null,
      content:     content,
      isModerated: false,
      sentAt:      DateTime.now().toIso8601String(),
      isMine:      true,
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(sentAt).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  bool get isOptimistic => id.startsWith('optimistic_');
}
