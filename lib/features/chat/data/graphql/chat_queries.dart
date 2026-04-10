class ChatQueries {
  ChatQueries._();

  // ── Load chat history ──────────────────────────
  // roomId = reservationId
  static const String chatHistory = '''
    query ChatHistory(\$roomId: ID!) {
      chatHistory(roomId: \$roomId) {
        id
        content
        isModerated
        sentAt
      }
    }
  ''';
}
