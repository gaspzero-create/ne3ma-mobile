class ProfileQueries {
  ProfileQueries._();

  // ── Get my profile ─────────────────────────────
  static const String me = '''
    query Me {
      me {
        id
        fullName
        email
        phoneNumber
        avatarUrl
        bio
        wilaya
        baladiya
        role
        status
        emailVerified
        phoneVerified
      }
    }
  ''';
}

class ProfileMutations {
  ProfileMutations._();

  // ── Update base profile ────────────────────────
  static const String updateProfile = '''
    mutation UpdateProfile(\$input: UpdateBaseProfileInput!) {
      updateProfile(input: \$input) {
        id
        fullName
        email
        phoneNumber
        avatarUrl
        bio
        wilaya
        baladiya
        role
        status
        emailVerified
        phoneVerified
      }
    }
  ''';
}