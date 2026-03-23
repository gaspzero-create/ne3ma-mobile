class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.avatarUrl,
  });

  // convenience getter
 

 factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id:       map['id']       ?? '',
    fullName: map['fullName'] ?? '',
    email:    map['email']    ?? '',
    role:     map['role']     ?? '',
    status:   map['status']   ?? '',
    avatarUrl: map['avatarUrl'],
  );
}
}
class AuthPayload {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthPayload({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthPayload.fromMap(Map<String, dynamic> map) {
    return AuthPayload(
      accessToken:  map['accessToken']  ?? '',
      refreshToken: map['refreshToken'] ?? '',
      user:         UserModel.fromMap(map['user'] ?? {}),
    );
  }
}
