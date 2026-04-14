enum NotificationType { reserved, confirmed, cancelled, chat, general }

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      type: _typeFromString(json['type'] as String?),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static NotificationType _typeFromString(String? value) {
    switch (value) {
      case 'reserved':
        return NotificationType.reserved;
      case 'confirmed':
        return NotificationType.confirmed;
      case 'cancelled':
        return NotificationType.cancelled;
      case 'chat':
        return NotificationType.chat;
      default:
        return NotificationType.general;
    }
  }
}
