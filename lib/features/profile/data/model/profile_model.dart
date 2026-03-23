class ProfileModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? wilaya;
  final String? baladiya;
  final String role;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;

  const ProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.wilaya,
    this.baladiya,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id:            map['id']            ?? '',
      fullName:      map['fullName']      ?? '',
      email:         map['email'],
      phoneNumber:   map['phoneNumber'],
      avatarUrl:     map['avatarUrl'],
      bio:           map['bio'],
      wilaya:        map['wilaya'],
      baladiya:      map['baladiya'],
      role:          map['role']          ?? 'USER',
      status:        map['status']        ?? 'ACTIVE',
      emailVerified: map['emailVerified'] ?? false,
      phoneVerified: map['phoneVerified'] ?? false,
    );
  }

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? wilaya,
    String? baladiya,
  }) {
    return ProfileModel(
      id:            id,
      fullName:      fullName    ?? this.fullName,
      email:         email,
      phoneNumber:   phoneNumber,
      avatarUrl:     avatarUrl   ?? this.avatarUrl,
      bio:           bio         ?? this.bio,
      wilaya:        wilaya      ?? this.wilaya,
      baladiya:      baladiya    ?? this.baladiya,
      role:          role,
      status:        status,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
    );
  }
}