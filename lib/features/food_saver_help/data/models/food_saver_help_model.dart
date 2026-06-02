enum FoodSaverHelpStatus { pending, submitted, cancelled, unknown }

class FoodSaverHelpModel {
  final String id;
  final FoodSaverHelpStatus status;
  final String? adminMessage;
  final double? distanceKm;
  final String? response;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admin info
  final String? adminId;
  final String? adminName;
  final String? adminAvatarUrl;

  // Report info
  final String? reportId;
  final String? reportReason;
  final String? reportDescription;
  final String? reportStatus;
  final String? relatedDonationTitle;
  final String? relatedMeetingZone;
  final double? relatedLat;
  final double? relatedLng;

  // Reported user info
  final String? reportedUserId;
  final String? reportedUserName;
  final String? reportedUserAvatarUrl;

  // Reporter info
  final String? reporterName;

  const FoodSaverHelpModel({
    required this.id,
    required this.status,
    this.adminMessage,
    this.distanceKm,
    this.response,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.adminId,
    this.adminName,
    this.adminAvatarUrl,
    this.reportId,
    this.reportReason,
    this.reportDescription,
    this.reportStatus,
    this.relatedDonationTitle,
    this.relatedMeetingZone,
    this.relatedLat,
    this.relatedLng,
    this.reportedUserId,
    this.reportedUserName,
    this.reportedUserAvatarUrl,
    this.reporterName,
  });

  bool get isPending => status == FoodSaverHelpStatus.pending;
  bool get isSubmitted => status == FoodSaverHelpStatus.submitted;

  factory FoodSaverHelpModel.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    final report = json['report'] as Map<String, dynamic>?;
    final reportedUser = report?['reportedUser'] as Map<String, dynamic>?;
    final reporter = report?['reporter'] as Map<String, dynamic>?;

    return FoodSaverHelpModel(
      id: json['id'] as String,
      status: _statusFromString(json['status'] as String?),
      adminMessage: json['adminMessage'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      response: json['response'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      adminId: admin?['id'] as String?,
      adminName: admin?['fullName'] as String?,
      adminAvatarUrl: admin?['avatarUrl'] as String?,
      reportId: report?['id'] as String?,
      reportReason: report?['reason'] as String?,
      reportDescription: report?['description'] as String?,
      reportStatus: report?['status'] as String?,
      relatedDonationTitle: report?['relatedDonationTitle'] as String?,
      relatedMeetingZone: report?['relatedMeetingZone'] as String?,
      relatedLat: (report?['relatedLat'] as num?)?.toDouble(),
      relatedLng: (report?['relatedLng'] as num?)?.toDouble(),
      reportedUserId: reportedUser?['id'] as String?,
      reportedUserName: reportedUser?['fullName'] as String?,
      reportedUserAvatarUrl: reportedUser?['avatarUrl'] as String?,
      reporterName: reporter?['fullName'] as String?,
    );
  }

  static FoodSaverHelpStatus _statusFromString(String? value) {
    switch (value) {
      case 'PENDING':
        return FoodSaverHelpStatus.pending;
      case 'SUBMITTED':
        return FoodSaverHelpStatus.submitted;
      case 'CANCELLED':
        return FoodSaverHelpStatus.cancelled;
      default:
        return FoodSaverHelpStatus.unknown;
    }
  }
}
