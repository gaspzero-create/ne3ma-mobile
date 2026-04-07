class DonationModel {
  final String id;
  final String title;
  final String? description;
  final String category;       // FRESH | DRY | URGENT
  final String status;         // AVAILABLE | RESERVED | CONFIRMED | COMPLETED | EXPIRED
  final String pickupType;     // PICKUP | DROP
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
    return DonationModel(
      id:                 map['id']                 ?? '',
      title:              map['title']              ?? '',
      description:        map['description'],
      category:           map['category']           ?? 'FRESH',
      status:             map['status']             ?? 'AVAILABLE',
      pickupType:         map['pickupType']         ?? 'PICKUP',
      quantity:           map['quantity']           ?? '',
      expiresAt:          map['expiresAt']          ?? '',
      imageUrl:           map['imageUrl'],
      lat:                (map['lat'] as num?)?.toDouble(),
      lng:                (map['lng'] as num?)?.toDouble(),
      meetingZone:        map['meetingZone'],
      distanceKm:         (map['distanceKm'] as num?)?.toDouble(),
      checklistConfirmed: map['checklistConfirmed'],
      createdAt:          map['createdAt']          ?? '',
    );
  }

  // ── Helpers ────────────────────────────────────
  bool get isAvailable  => status == 'AVAILABLE';
  bool get isUrgent     => category == 'URGENT';
  bool get isFresh      => category == 'FRESH';
  bool get isDry        => category == 'DRY';

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
  final String? confirmedAt;

  const ReservationModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id:          map['id']          ?? '',
      status:      map['status']      ?? 'PENDING',
      createdAt:   map['createdAt']   ?? '',
      confirmedAt: map['confirmedAt'],
    );
  }
}
