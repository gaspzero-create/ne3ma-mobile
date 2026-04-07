class AuthMutations {
  AuthMutations._();

  // ── Register ───────────────────────────────────────
static const String register = '''
  mutation Register(\$input: RegisterInput!) {
    register(input: \$input) {
      accessToken
      refreshToken
      user {
        id
        fullName
        email
        role
        status
      }
    }
  }
''';

  // ── Login ──────────────────────────────────────────
static const String login = '''
  mutation Login(\$input: LoginInput!) {
    login(input: \$input) {
      accessToken
      refreshToken
      user {
        id
        fullName
        email
        role
        status
      }
    }
  }
''';

  // ── Refresh Token ──────────────────────────────────
  static const String refreshToken = '''
    mutation RefreshToken(\$input: RefreshTokenInput!) {
      refreshToken(input: \$input) {
        accessToken
        refreshToken
      }
    }
  ''';

  // ── Send Email OTP ─────────────────────────────────
static const String sendEmailOtp = '''
  mutation SendEmailOtp(\$input: EmailOtpInput!) {
    sendEmailOtp(input: \$input)
  }
''';

  // ── Verify Email OTP ───────────────────────────────
  static const String verifyEmailOtp = '''
    mutation VerifyEmailOtp(\$input: VerifyEmailOtpInput!) {
      verifyEmailOtp(input: \$input) {
        accessToken
        refreshToken
        user {
          id
          fullName
          email
          role
          status
        }
      }
    }
  ''';

  // ── Send Phone OTP ─────────────────────────────────
  static const String sendPhoneOtp = '''
  mutation SendPhoneOtp(\$input: PhoneOtpInput!) {
    sendPhoneOtp(input: \$input)
  }
''';

  // ── Verify Phone OTP ──────────────────────────────
  static const String verifyPhoneOtp = '''
    mutation VerifyPhoneOtp(\$input: VerifyPhoneOtpInput!) {
      verifyPhoneOtp(input: \$input) {
        accessToken
        refreshToken
        user {
          id
          fullName
          email
          role
          status
        }
      }
    }
  ''';
}
