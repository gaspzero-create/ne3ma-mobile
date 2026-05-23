import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/features/reports/data/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

class ReportState {
  final bool isSubmitting;
  final String? error;

  const ReportState({
    this.isSubmitting = false,
    this.error,
  });

  ReportState copyWith({
    bool? isSubmitting,
    String? error,
  }) {
    return ReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier(this._repository) : super(const ReportState());

  final ReportRepository _repository;

  Future<bool> submitReport({
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final success = await _repository.createReport(
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
      );

      state = state.copyWith(isSubmitting: false, error: null);
      return success;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final reportProvider = StateNotifierProvider.autoDispose<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref.read(reportRepositoryProvider));
});
