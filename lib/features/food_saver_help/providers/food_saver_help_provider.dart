import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/features/food_saver_help/data/models/food_saver_help_model.dart';
import 'package:ne3ma/features/food_saver_help/data/repositories/food_saver_help_repository.dart';

// ── Repository provider ────────────────────────────────
final foodSaverHelpRepositoryProvider = Provider<FoodSaverHelpRepository>((
  ref,
) {
  return FoodSaverHelpRepository();
});

// ── State ──────────────────────────────────────────────
class FoodSaverHelpState {
  final List<FoodSaverHelpModel> requests;
  final bool isLoading;
  final String? error;

  const FoodSaverHelpState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  FoodSaverHelpState copyWith({
    List<FoodSaverHelpModel>? requests,
    bool? isLoading,
    String? error,
  }) {
    return FoodSaverHelpState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────
class FoodSaverHelpNotifier extends StateNotifier<FoodSaverHelpState> {
  final FoodSaverHelpRepository _repository;

  FoodSaverHelpNotifier(this._repository) : super(const FoodSaverHelpState()) {
    fetch();
  }

  Future<void> fetch() async {
    debugPrint('📤 FoodSaverHelpProvider: Fetching...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requests = await _repository.fetchMyHelpRequests();
      debugPrint('✅ FoodSaverHelpProvider: ${requests.length} requests');
      state = state.copyWith(isLoading: false, requests: requests);
    } catch (e) {
      debugPrint('❌ FoodSaverHelpProvider: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitResponse({
    required String requestId,
    required String response,
  }) async {
    debugPrint('📤 FoodSaverHelpProvider: Submitting response...');
    try {
      final success = await _repository.submitResponse(
        requestId: requestId,
        response: response,
      );
      if (success) {
        await fetch(); // Refresh list
      }
      return success;
    } catch (e) {
      debugPrint('❌ FoodSaverHelpProvider: Submit failed - $e');
      return false;
    }
  }
}

// ── Provider ───────────────────────────────────────────
final foodSaverHelpProvider =
    StateNotifierProvider<FoodSaverHelpNotifier, FoodSaverHelpState>((ref) {
      return FoodSaverHelpNotifier(ref.read(foodSaverHelpRepositoryProvider));
    });
