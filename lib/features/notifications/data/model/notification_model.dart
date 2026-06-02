import 'dart:convert';

enum NotificationType {
  reservation,
  cancellation,
  completion,
  warning,
  message,
  nearbyDonation,
  foodSaverHelpRequest,
  foodSaverHelpResponse,
  unknown,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? data;
  final DateTime createdAt;
  final bool isRead;
  final String? userId;
  final String? userName;
  final String? userAvatarUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.userId,
    this.userName,
    this.userAvatarUrl,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: _typeFromString(json['type'] as String?),
      data: json['data'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      userId: user?['id'] as String?,
      userName: user?['fullName'] as String?,
      userAvatarUrl: user?['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> get dataMap {
    final raw = data;
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Ignore malformed notification data and fall back to an empty map.
    }

    return const {};
  }

  String? get donationId => dataMap['donationId']?.toString();

  String? get reservationId => dataMap['reservationId']?.toString();

  String? get foodSaverHelpRequestId =>
      dataMap['requestId']?.toString() ??
      dataMap['foodSaverHelpRequestId']?.toString() ??
      dataMap['helpRequestId']?.toString();

  static NotificationType _typeFromString(String? value) {
    switch (value) {
      case 'RESERVATION':
        return NotificationType.reservation;
      case 'CANCELLATION':
        return NotificationType.cancellation;
      case 'COMPLETION':
        return NotificationType.completion;
      case 'WARNING':
        return NotificationType.warning;
      case 'MESSAGE':
        return NotificationType.message;
      case 'NEARBY_DONATION':
        return NotificationType.nearbyDonation;
      case 'FOOD_SAVER_HELP_REQUEST':
        return NotificationType.foodSaverHelpRequest;
      case 'FOOD_SAVER_HELP_RESPONSE':
        return NotificationType.foodSaverHelpResponse;
      default:
        return NotificationType.unknown;
    }
  }
}
