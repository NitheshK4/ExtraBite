import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/report_model.dart';
import '../demo/seed_data.dart';

class ReportNotifier extends StateNotifier<List<ReportModel>> {
  ReportNotifier() : super(SeedData.generateReports());

  void submitReport({
    required String reporterId,
    required String reporterName,
    String? listingId,
    String? listingTitle,
    String? pgId,
    String? pgName,
    required String reason,
    required String description,
    String? imageEvidenceUrl,
  }) {
    final newReport = ReportModel(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reporterId: reporterId,
      reporterName: reporterName,
      listingId: listingId,
      listingTitle: listingTitle,
      pgId: pgId,
      pgName: pgName,
      reason: reason,
      description: description,
      imageEvidenceUrl: imageEvidenceUrl,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    state = [newReport, ...state];
  }

  void resolveReport(String reportId, String adminNotes) {
    final index = state.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final list = [...state];
      list[index] = list[index].copyWith(
        status: 'resolved',
        adminNotes: adminNotes,
      );
      state = list;
    }
  }

  void dismissReport(String reportId, String adminNotes) {
    final index = state.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final list = [...state];
      list[index] = list[index].copyWith(
        status: 'dismissed',
        adminNotes: adminNotes,
      );
      state = list;
    }
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, List<ReportModel>>((ref) {
  return ReportNotifier();
});
