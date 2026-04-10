class AuthQueries {
  AuthQueries._();

  static const String me = '''
    query Me {
      me {
        id
        fullName
        email
        phoneNumber
        avatarUrl
        role
        status
        emailVerified
        phoneVerified
      }
    }
  ''';
}