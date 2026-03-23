import 'package:flutter_riverpod/flutter_riverpod.dart';

// Example provider for app state management
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class AppState {
  final bool isLoading;
  final String? error;

  const AppState({
    this.isLoading = false,
    this.error,
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
