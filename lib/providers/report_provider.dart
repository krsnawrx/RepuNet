import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';

enum ReportStatus { initial, loading, success, error }

class ReportState {
  final ReportStatus status;
  final String? errorMessage;

  ReportState({this.status = ReportStatus.initial, this.errorMessage});

  ReportState copyWith({ReportStatus? status, String? errorMessage}) {
    return ReportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _service;

  ReportNotifier(this._service) : super(ReportState());

  Future<void> submitReport({
    required String reportedId,
    required String reason,
    String? details,
  }) async {
    state = state.copyWith(status: ReportStatus.loading);
    try {
      await _service.submitReport(
        reportedId: reportedId,
        reason: reason,
        details: details,
      );
      state = state.copyWith(status: ReportStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ReportStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = ReportState();
  }
}

final reportServiceProvider = Provider((ref) => ReportService());
final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref.watch(reportServiceProvider));
});
