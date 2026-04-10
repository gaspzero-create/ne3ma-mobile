import 'package:flutter/material.dart';
import 'package:ne3ma/features/auth/data/graphql/auth_queries.dart';

import '../../../../core/network/graphql_client.dart';
import '../graphql/auth_mutations.dart';
import '../models/user_model.dart';

class AuthRepository {

  // ── Register ───────────────────────────────────────
Future<AuthPayload> register({
  required String fullName,
  required String email,
  required String password,
}) async {
  final data = await GraphQLClient.query(
    document: AuthMutations.register,
    variables: {
      'input': {
        'fullName': fullName,
        'email':    email,
        'password': password,
      },
    },
  );
  final payload = AuthPayload.fromMap(data['register']);
  await GraphQLClient.saveTokens(
    accessToken:  payload.accessToken,
    refreshToken: payload.refreshToken,
  );
  return payload;
}
  // ── Login ──────────────────────────────────────────
  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final data = await GraphQLClient.query(
      document: AuthMutations.login,
      variables: {
        'input': {
          'email':    email,
          'password': password,
        },
      },
    );

    final payload = AuthPayload.fromMap(data['login']);

    await GraphQLClient.saveTokens(
      accessToken:  payload.accessToken,
      refreshToken: payload.refreshToken,
    );

    return payload;
  }

  // ── Logout ─────────────────────────────────────────
  Future<void> logout() async {
    await GraphQLClient.clearTokens();
  }

  // ── Check if logged in ─────────────────────────────
  Future<bool> isAuthenticated() async {
    final token = await GraphQLClient.getAccessToken();
    return token != null;
  }

  // ── Send Email OTP ─────────────────────────────────
  Future<void> sendEmailOtp({required String email}) async {
    await GraphQLClient.query(
      document: AuthMutations.sendEmailOtp,
      variables: {'input': {'email': email}},
    );
  }

  // ── Verify Email OTP ───────────────────────────────
  Future<AuthPayload> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final data = await GraphQLClient.query(
      document: AuthMutations.verifyEmailOtp,
      variables: {
        'input': {'email': email, 'otp': otp},
      },
    );

    final payload = AuthPayload.fromMap(data['verifyEmailOtp']);
    await GraphQLClient.saveTokens(
      accessToken:  payload.accessToken,
      refreshToken: payload.refreshToken,
    );
    return payload;
  }

  // ── Send Phone OTP ─────────────────────────────────
  Future<void> sendPhoneOtp({required String phoneNumber}) async {
  await GraphQLClient.query(
    document: AuthMutations.sendPhoneOtp,
    variables: {'input': {'phoneNumber': phoneNumber}},
  );
}

  // ── Verify Phone OTP ───────────────────────────────
  Future<AuthPayload> verifyPhoneOtp({
  required String phoneNumber,
  required String otp,
}) async {
  final data = await GraphQLClient.query(
    document: AuthMutations.verifyPhoneOtp,
    variables: {
      'input': {'phoneNumber': phoneNumber, 'otp': otp},
    },
  );
  final payload = AuthPayload.fromMap(data['verifyPhoneOtp']);
  await GraphQLClient.saveTokens(
    accessToken:  payload.accessToken,
    refreshToken: payload.refreshToken,
  );
  return payload;
}

// Add this method
Future<UserModel> getMe() async {
  debugPrint('📤 AuthRepo: Fetching current user...');
  final data = await GraphQLClient.query(
    document: AuthQueries.me,
  );
  debugPrint('✅ AuthRepo: Got current user');
  return UserModel.fromMap(data['me']);
}
}
