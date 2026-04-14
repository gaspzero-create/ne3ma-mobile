import 'package:flutter/material.dart';
import '../../../../core/network/graphql_client.dart';
import '../graphql/chat_queries.dart';
import '../models/chat_message_model.dart';

class ChatRepository {

  // ── Load chat history from GraphQL ────────────
  Future<List<ChatMessageModel>> getChatHistory(
    String roomId, {
    String? currentUserId,
    Set<String>? knownMineIds,
  }) async {
    debugPrint('📤 ChatRepo: Loading history for room $roomId...');
    try {
      final data = await GraphQLClient.query(
        document: ChatQueries.chatHistory,
        variables: {'roomId': roomId},
      );
      final list = data['chatHistory'] as List;
      debugPrint('✅ ChatRepo: Got ${list.length} messages');
      return list
          .map(
            (e) => ChatMessageModel.fromMap(
              e,
              currentUserId: currentUserId,
              knownMineIds: knownMineIds,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ ChatRepo: History error - $e');
      rethrow;
    }
  }
}
