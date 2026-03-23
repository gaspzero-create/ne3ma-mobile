import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/features/profile/data/model/profile_model.dart';
import 'package:ne3ma/features/profile/data/repository/profile_repository.dart';


// ── Repository provider ────────────────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// ── Profile State ──────────────────────────────────────
class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile:   profile   ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

// ── Profile Notifier ───────────────────────────────────
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState()) {
    fetchProfile();  // auto-fetch on init
  }

  // ── Fetch profile ──────────────────────────────
  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getMe();
      debugPrint('✅ ProfileProvider: Profile loaded - ${profile.fullName}');
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      debugPrint('❌ ProfileProvider: Error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Update profile ─────────────────────────────
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? wilaya,
    String? baladiya,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateProfile(
        fullName:  fullName,
        bio:       bio,
        avatarUrl: avatarUrl,
        wilaya:    wilaya,
        baladiya:  baladiya,
      );
      debugPrint('✅ ProfileProvider: Profile updated - ${updated.fullName}');
      state = state.copyWith(isLoading: false, profile: updated);
      return true;
    } catch (e) {
      debugPrint('❌ ProfileProvider: Update error - $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider));
});