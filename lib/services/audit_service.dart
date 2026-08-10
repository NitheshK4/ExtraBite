import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_event_model.dart';
import '../models/user_model.dart';
import '../data/demo/seed_data.dart';

class AuditNotifier extends StateNotifier<List<AuditEventModel>> {
  AuditNotifier() : super(SeedData.generateAuditLogs());

  void logEvent({
    required UserModel actor,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> details = const {},
  }) {
    final event = AuditEventModel(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      actorId: actor.id,
      actorName: actor.fullName,
      actorRole: actor.role,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      timestamp: DateTime.now(),
    );

    state = [event, ...state];
  }
}

final auditProvider =
    StateNotifierProvider<AuditNotifier, List<AuditEventModel>>((ref) {
  return AuditNotifier();
});
