import 'package:flutter/material.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/features/notifications/data/graphql/notification_queries.dart';
import 'package:ne3ma/features/notifications/data/model/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getMyNotifications() async {
    debugPrint('📤 NotificationsRepo: Fetching notifications...');
    final data = await GraphQLClient.query(
      document: NotificationQueries.myNotifications,
    );
    final list = data['myNotifications'] as List? ?? const [];
    debugPrint('✅ NotificationsRepo: Got ${list.length} notifications');
    return list
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> markNotificationAsRead(String id) async {
    debugPrint('📤 NotificationsRepo: Marking $id as read...');
    final data = await GraphQLClient.query(
      document: NotificationQueries.markAsRead,
      variables: {'id': id},
    );
    return data['markNotificationAsRead'] as bool? ?? false;
  }
}
