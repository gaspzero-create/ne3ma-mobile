class LeaderboardEntryModel {
  final int    rank;
  final String fullName;
  final int    points;
  final String badge;   // NONE | BRONZE | SILVER | GOLD | FOOD_DONATOR
  final String role;
  final String? wilaya;

  const LeaderboardEntryModel({
    required this.rank,
    required this.fullName,
    required this.points,
    required this.badge,
    required this.role,
    this.wilaya,
  });

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryModel(
      rank:     (map['rank']   as num?)?.toInt() ?? 0,
      fullName: map['fullName'] ?? '',
      points:   (map['points'] as num?)?.toInt() ?? 0,
      badge:    map['badge']   ?? 'NONE',
      role:     map['role']    ?? 'USER',
      wilaya:   map['wilaya'],
    );
  }

  // ── Helpers ────────────────────────────────────
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get roleLabel {
    switch (role) {
      case 'USER':        return 'Donor';
      case 'ASSOCIATION': return 'Association';
      case 'MAYOR':       return 'Mayor';
      case 'ADMIN':       return 'Admin';
      default:            return role;
    }
  }

  String get badgeEmoji {
    switch (badge) {
      case 'GOLD':         return '🥇';
      case 'SILVER':       return '🥈';
      case 'BRONZE':       return '🥉';
      case 'FOOD_DONATOR': return '🌟';
      default:             return '';
    }
  }

  bool get hasBadge => badge != 'NONE';
}
