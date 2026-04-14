class NotificationQueries {
  static const String myNotifications = '''
    query MyNotifications {
      myNotifications {
        id
        title
        subtitle
        type
        imageUrl
        createdAt
        isRead
      }
    }
  ''';

  static const String markAsRead = '''
    mutation MarkNotificationAsRead(\$id: String!) {
      markNotificationAsRead(id: \$id)
    }
  ''';

  static const String markAllAsRead = '''
    mutation MarkAllNotificationsAsRead {
      markAllNotificationsAsRead
    }
  ''';
}
