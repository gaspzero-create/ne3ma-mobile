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
  final int quantityAvailable;
  final int quantityTotal;
  final String? donorId;
  final String? donorName;
  final String? donorAvatarUrl;
  final String? donorBadge;
  final String? donorRole;
  final String? donorWilaya;
  final String? donorBaladiya;
  final String expiresAt;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final String? meetingZone;
  final double? distanceKm;
  final bool? checklistConfirmed;
  final String createdAt;
  final String? updatedAt;

  const DonationModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.categoryId,
    required this.status,
    required this.pickupType,
    required this.quantity,
    this.quantityAvailable = 1,
    this.quantityTotal = 1,
    this.donorId,
    this.donorName,
    this.donorAvatarUrl,
    this.donorBadge,
    this.donorRole,
    this.donorWilaya,
    this.donorBaladiya,
    required this.expiresAt,
    this.imageUrl,
    this.lat,
    this.lng,
    this.meetingZone,
    this.distanceKm,
    this.checklistConfirmed,
    required this.createdAt,
    this.updatedAt,
  });

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    final parsedCategory = _parseCategory(map['category']);
    final donor = map['donor'] is Map
        ? Map<String, dynamic>.from(map['donor'] as Map)
        : null;

    return DonationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: parsedCategory.name,
      categoryId: parsedCategory.id,
      status: map['status'] ?? 'AVAILABLE',
      pickupType: map['pickupType'] ?? 'PICKUP',
      quantity: map['quantity'] ?? '',
      quantityAvailable: (map['quantityAvailable'] as num?)?.toInt() ?? 1,
      quantityTotal: (map['quantityTotal'] as num?)?.toInt() ?? 1,
      donorId: donor?['id'],
      donorName: donor?['fullName'] ?? donor?['name'],
      donorAvatarUrl: donor?['avatarUrl'],
      donorBadge: donor?['badge'],
      donorRole: donor?['role'],
      donorWilaya: donor?['wilaya'],
      donorBaladiya: donor?['baladiya'],
      expiresAt: map['expiresAt'] ?? '',
      imageUrl: map['imageUrl'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      meetingZone: map['meetingZone'],
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      checklistConfirmed: map['checklistConfirmed'],
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'],
    );
  }

  DonationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? categoryId,
    String? status,
    String? pickupType,
    String? quantity,
    int? quantityAvailable,
    int? quantityTotal,
    String? donorId,
    String? donorName,
    String? donorAvatarUrl,
    String? donorBadge,
    String? donorRole,
    String? donorWilaya,
    String? donorBaladiya,
    String? expiresAt,
    String? imageUrl,
    double? lat,
    double? lng,
    String? meetingZone,
    double? distanceKm,
    bool? checklistConfirmed,
    String? createdAt,
    String? updatedAt,
  }) {
    return DonationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      pickupType: pickupType ?? this.pickupType,
      quantity: quantity ?? this.quantity,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      quantityTotal: quantityTotal ?? this.quantityTotal,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorAvatarUrl: donorAvatarUrl ?? this.donorAvatarUrl,
      donorBadge: donorBadge ?? this.donorBadge,
      donorRole: donorRole ?? this.donorRole,
      donorWilaya: donorWilaya ?? this.donorWilaya,
      donorBaladiya: donorBaladiya ?? this.donorBaladiya,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      meetingZone: meetingZone ?? this.meetingZone,
      distanceKm: distanceKm ?? this.distanceKm,
      checklistConfirmed: checklistConfirmed ?? this.checklistConfirmed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helpers ────────────────────────────────────
  bool get isAvailable => status == 'AVAILABLE' && quantityAvailable > 0;

  String get availableQuantityLabel =>
      '$quantityAvailable / $quantityTotal available ($quantity)';
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
  final String? donorId;

  // ── Beneficiary info (from myDonationReservations) ─
  final String? beneficiaryId;
  final String? beneficiaryName;
  final String? beneficiaryPhoneNumber;
  final String? beneficiaryEmail;
  final String? beneficiaryWilaya;
  final String? beneficiaryBaladiya;
  final String? beneficiaryAvatarUrl;
  final String? beneficiaryBadge;
  final String? beneficiaryRole;

  // ── Donor info (from myReservations) ─
  final String? donorName;
  final String? donorAvatarUrl;
  final String? donorBadge;
  final String? donorRole;
  final String? donorWilaya;
  final String? donorBaladiya;

  // ── Donation info (from myDonationReservations) ─
  final String? donationId;
  final String? donationTitle;
  final String? donationCategory;
  final String? donationCategoryId;
  final String? donationImageUrl;
  final String? donationMeetingZone;
  final String? donationPickupType;
  final String? donationQuantity;
  final double? donationLat;
  final double? donationLng;

  const ReservationModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.reservedAt,
    this.confirmedAt,
    this.updatedAt,
    this.donorId,
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryPhoneNumber,
    this.beneficiaryEmail,
    this.beneficiaryWilaya,
    this.beneficiaryBaladiya,
    this.beneficiaryAvatarUrl,
    this.beneficiaryBadge,
    this.beneficiaryRole,
    this.donorName,
    this.donorAvatarUrl,
    this.donorBadge,
    this.donorRole,
    this.donorWilaya,
    this.donorBaladiya,
    this.donationId,
    this.donationTitle,
    this.donationCategory,
    this.donationCategoryId,
    this.donationImageUrl,
    this.donationMeetingZone,
    this.donationPickupType,
    this.donationQuantity,
    this.donationLat,
    this.donationLng,
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
      donorId: parsedDonor?['id'],
      beneficiaryId: beneficiary?['id'],
      beneficiaryName: beneficiary?['fullName'],
      beneficiaryPhoneNumber: beneficiary?['phoneNumber'],
      beneficiaryEmail: beneficiary?['email'],
      beneficiaryWilaya: beneficiary?['wilaya'],
      beneficiaryBaladiya: beneficiary?['baladiya'],
      beneficiaryAvatarUrl: beneficiary?['avatarUrl'],
      beneficiaryBadge: beneficiary?['badge'],
      beneficiaryRole: beneficiary?['role'],
      donorName: parsedDonor?['fullName'] ?? parsedDonor?['name'],
      donorAvatarUrl: parsedDonor?['avatarUrl'],
      donorBadge: parsedDonor?['badge'],
      donorRole: parsedDonor?['role'],
      donorWilaya: parsedDonor?['wilaya'],
      donorBaladiya: parsedDonor?['baladiya'],
      donationId: donation?['id'],
      donationTitle: donation?['title'],
      donationCategory: parsedCategory.name,
      donationCategoryId: parsedCategory.id,
      donationImageUrl: donation?['imageUrl'],
      donationMeetingZone: donation?['meetingZone'],
      donationPickupType: donation?['pickupType'],
      donationQuantity: donation?['quantity'],
      donationLat: (donation?['lat'] as num?)?.toDouble(),
      donationLng: (donation?['lng'] as num?)?.toDouble(),
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
