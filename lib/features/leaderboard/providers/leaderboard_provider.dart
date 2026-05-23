import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/leaderboard_model.dart';
import '../data/repositories/leaderboard_repository.dart';

// ── Repository provider ────────────────────────────────
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

// ── State ──────────────────────────────────────────────
class LeaderboardState {
  final List<LeaderboardEntryModel> entries;
  final bool    isLoading;
  final String? error;
  final String? selectedWilaya;   // null = all Algeria
  final String  selectedFilter;   // 'ALL' | 'TOP_DONORS' | 'FOOD_SAVER'

  const LeaderboardState({
    this.entries        = const [],
    this.isLoading      = false,
    this.error,
    this.selectedWilaya,
    this.selectedFilter = 'ALL',
  });

  LeaderboardState copyWith({
    List<LeaderboardEntryModel>? entries,
    bool?    isLoading,
    String?  error,
    String?  selectedWilaya,
    bool     clearWilaya = false,
    String?  selectedFilter,
  }) {
    return LeaderboardState(
      entries:        entries        ?? this.entries,
      isLoading:      isLoading      ?? this.isLoading,
      error:          error,
      selectedWilaya: clearWilaya ? null : selectedWilaya ?? this.selectedWilaya,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

// ── Notifier ───────────────────────────────────────────
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardNotifier(this._repository) : super(const LeaderboardState()) {
    fetch(); // auto-fetch on init
  }

  Future<void> fetch({String? wilaya}) async {
    debugPrint('📤 LeaderboardProvider: Fetching...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final selectedWilaya = wilaya ?? state.selectedWilaya;
      final entries = await _repository.getLeaderboard(
        wilaya: selectedWilaya,
      );
      debugPrint('✅ LeaderboardProvider: ${entries.length} entries');
      state = state.copyWith(
        isLoading: false,
        entries: entries,
        selectedWilaya: selectedWilaya,
      );
    } catch (e) {
      debugPrint('❌ LeaderboardProvider: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Filter by wilaya ───────────────────────────
  void filterByWilaya(String? wilaya) {
    debugPrint('🔍 LeaderboardProvider: Filter wilaya = $wilaya');
    state = state.copyWith(
      selectedWilaya: wilaya,
      clearWilaya:    wilaya == null,
    );
  }

  // ── Set tab filter ─────────────────────────────
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  // ── Filtered entries based on tab ──────────────
  List<LeaderboardEntryModel> get filteredEntries {
    var entries = state.entries;

    final selectedWilaya = state.selectedWilaya;
    if (selectedWilaya != null && selectedWilaya.trim().isNotEmpty) {
      entries = entries
          .where(
            (e) =>
                e.wilaya != null &&
                e.wilaya!.trim().toLowerCase() ==
                    selectedWilaya.trim().toLowerCase(),
          )
          .toList();
    }

    switch (state.selectedFilter) {
      case 'TOP_DONORS':
        return entries
            .where((e) => e.role == 'USER' || e.role == 'ASSOCIATION')
            .toList();
      case 'FOOD_SAVER':
        return entries
            .where((e) => e.badge == 'FOOD_DONATOR' || e.badge == 'GOLD')
            .toList();
      default:
        return entries;
    }
  }
}

// ── Provider ───────────────────────────────────────────
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.read(leaderboardRepositoryProvider));
});
