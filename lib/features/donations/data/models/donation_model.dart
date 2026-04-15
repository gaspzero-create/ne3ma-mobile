import '../../utils/category_utils.dart';

class DonationModel {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? categoryId;
  final String status; // AVAILABLE | RESERVED | CONFIRMED | COMPLETED | EXPIRED
  final String pickupType; // PICKUP | DROP
  final String quantity;
  final String expiresAt;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final String? meetingZone;
  final double? distanceKm;
  final bool? checklistConfirmed;
  final String createdAt;

  const DonationModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.categoryId,
    required this.status,
    required this.pickupType,
    required this.quantity,
    required this.expiresAt,
    this.imageUrl,
    this.lat,
    this.lng,
    this.meetingZone,
    this.distanceKm,
    this.checklistConfirmed,
    required this.createdAt,
  });

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    final parsedCategory = _parseCategory(map['category']);

    return DonationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: parsedCategory.name,
      categoryId: parsedCategory.id,
      status: map['status'] ?? 'AVAILABLE',
      pickupType: map['pickupType'] ?? 'PICKUP',
      quantity: map['quantity'] ?? '',
      expiresAt: map['expiresAt'] ?? '',
      imageUrl: map['imageUrl'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      meetingZone: map['meetingZone'],
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      checklistConfirmed: map['checklistConfirmed'],
      createdAt: map['createdAt'] ?? '',
    );
  }

  // ── Helpers ────────────────────────────────────
  bool get isAvailable => status == 'AVAILABLE';
  bool get isUrgent => isUrgentCategory(category);
  bool get isFresh => isFreshCategory(category);
  bool get isDry => isDryCategory(category);
  String get categoryKey => categoryId ?? category;

  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).toInt()}m';
    return '${distanceKm!.toStringAsFixed(1)}km';
  }
}

class ReservationModel {
  final String id;
  final String status;
  final String createdAt;
  final String reservedAt;
  final String? confirmedAt;
  final String? updatedAt;

  // ── Beneficiary info (from myDonationReservations) ─
  final String? beneficiaryId;
  final String? beneficiaryName;
  final String? beneficiaryPhoneNumber;
  final String? beneficiaryEmail;
  final String? beneficiaryWilaya;
  final String? beneficiaryBaladiya;
  final String? beneficiaryAvatarUrl;

  // ── Donor info (from myReservations) ─
  final String? donorName;
  final String? donorAvatarUrl;

  // ── Donation info (from myDonationReservations) ─
  final String? donationId;
  final String? donationTitle;
  final String? donationCategory;
  final String? donationCategoryId;
  final String? donationImageUrl;
  final String? donationMeetingZone;
  final String? donationPickupType;
  final String? donationQuantity;

  const ReservationModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.reservedAt,
    this.confirmedAt,
    this.updatedAt,
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryPhoneNumber,
    this.beneficiaryEmail,
    this.beneficiaryWilaya,
    this.beneficiaryBaladiya,
    this.beneficiaryAvatarUrl,
    this.donorName,
    this.donorAvatarUrl,
    this.donationId,
    this.donationTitle,
    this.donationCategory,
    this.donationCategoryId,
    this.donationImageUrl,
    this.donationMeetingZone,
    this.donationPickupType,
    this.donationQuantity,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    final beneficiary = map['beneficiary'] is Map
        ? Map<String, dynamic>.from(map['beneficiary'] as Map)
        : null;
    final donation = map['donation'] is Map
        ? Map<String, dynamic>.from(map['donation'] as Map)
        : null;
    final parsedCategory = _parseCategory(donation?['category']);

    // Attempt to parse donor info if available
    final dynamic donorMap =
        map['donor'] ?? donation?['donor'] ?? donation?['user'];
    final parsedDonor = donorMap is Map
        ? Map<String, dynamic>.from(donorMap)
        : null;

    return ReservationModel(
      id: map['id'] ?? '',
      status: map['status'] ?? 'PENDING',
      createdAt: map['createdAt'] ?? '',
      reservedAt: map['reservedAt'] ?? map['createdAt'] ?? '',
      confirmedAt: map['confirmedAt'],
      updatedAt: map['updatedAt'],
      beneficiaryId: beneficiary?['id'],
      beneficiaryName: beneficiary?['fullName'],
      beneficiaryPhoneNumber: beneficiary?['phoneNumber'],
      beneficiaryEmail: beneficiary?['email'],
      beneficiaryWilaya: beneficiary?['wilaya'],
      beneficiaryBaladiya: beneficiary?['baladiya'],
      beneficiaryAvatarUrl: beneficiary?['avatarUrl'],
      donorName: parsedDonor?['fullName'] ?? parsedDonor?['name'],
      donorAvatarUrl: parsedDonor?['avatarUrl'],
      donationId: donation?['id'],
      donationTitle: donation?['title'],
      donationCategory: parsedCategory.name,
      donationCategoryId: parsedCategory.id,
      donationImageUrl: donation?['imageUrl'],
      donationMeetingZone: donation?['meetingZone'],
      donationPickupType: donation?['pickupType'],
      donationQuantity: donation?['quantity'],
    );
  }
}

class _ParsedCategory {
  final String? id;
  final String name;

  const _ParsedCategory({required this.id, required this.name});
}

_ParsedCategory _parseCategory(dynamic rawCategory) {
  if (rawCategory is Map) {
    final map = Map<String, dynamic>.from(rawCategory);
    return _ParsedCategory(id: map['id'], name: map['name'] ?? 'Other');
  }

  if (rawCategory is String && rawCategory.trim().isNotEmpty) {
    return _ParsedCategory(id: null, name: rawCategory);
  }

  return const _ParsedCategory(id: null, name: 'Other');
}
