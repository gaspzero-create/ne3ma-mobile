class ChatMessageModel {
  final String id;
  final String content;
  final bool   isModerated;
  final String sentAt;

  // ── UI helpers (not from backend) ─────────────
  final bool   isMine;   // set locally based on current user

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isModerated,
    required this.sentAt,
    this.isMine = false,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map, {
    String? currentUserId,
  }) {
    return ChatMessageModel(
      id:          map['id']          ?? '',
      content:     map['content']     ?? '',
      isModerated: map['isModerated'] ?? false,
      sentAt:      map['sentAt']      ?? '',
      isMine:      false, // history messages — we don't know sender from schema yet
    );
  }

  // ── For socket newMessage ──────────────────────
  factory ChatMessageModel.fromSocket(
    Map<String, dynamic> map, {
    bool isMine = false,
  }) {
    return ChatMessageModel(
      id:          map['id']          ?? DateTime.now().toString(),
      content:     map['content']     ?? '',
      isModerated: map['isModerated'] ?? false,
      sentAt:      map['sentAt']      ?? DateTime.now().toIso8601String(),
      isMine:      isMine,
    );
  }

  // ── Optimistic message (before server confirms) ─
  factory ChatMessageModel.optimistic({
    required String content,
  }) {
    return ChatMessageModel(
      id:          'optimistic_${DateTime.now().millisecondsSinceEpoch}',
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
