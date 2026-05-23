import 'package:flutter/material.dart';
import 'package:ne3ma/features/profile/data/model/profile_model.dart';

import '../../../../core/network/graphql_client.dart';
import '../graphql/profile_queries.dart';


class ProfileRepository {

  // ── Get current user profile ───────────────────
  Future<ProfileModel> getMe() async {
    debugPrint('📤 Profile: Fetching profile...');
    final data = await GraphQLClient.query(
      document: ProfileQueries.me,
    );
    debugPrint('✅ Profile: Fetched successfully');
    return ProfileModel.fromMap(data['me']);
  }

  // ── Update profile ─────────────────────────────
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? wilaya,
    String? baladiya,
    String? pushToken,
  }) async {
    debugPrint('📤 Profile: Updating profile...');

    // Only send non-null fields
    final input = <String, dynamic>{};
    if (fullName  != null) input['fullName']  = fullName;
    if (bio       != null) input['bio']       = bio;
    if (avatarUrl != null) input['avatarUrl'] = avatarUrl;
    if (wilaya    != null) input['wilaya']    = wilaya;
    if (baladiya  != null) input['baladiya']  = baladiya;
    if (pushToken != null) input['pushToken'] = pushToken;

    final data = await GraphQLClient.query(
      document: ProfileMutations.updateProfile,
      variables: {'input': input},
    );
    debugPrint('✅ Profile: Updated successfully');
    return ProfileModel.fromMap(data['updateProfile']);
  }

  Future<void> updatePushToken(String pushToken) async {
    await updateProfile(pushToken: pushToken);
  }
}
