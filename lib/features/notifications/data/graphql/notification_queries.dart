class NotificationQueries {
  NotificationQueries._();

  static const String myNotifications = '''
    query MyNotifications {
      myNotifications {
        id
        title
        body
        data
        createdAt
        isRead
        type
      }
    }
  ''';

  static const String markAsRead = '''
    mutation MarkNotificationAsRead(\$id: ID!) {
      markNotificationAsRead(id: \$id)
    }
  ''';
}
