import 'user_model.dart';

class AuditEventModel {
  final String id;
  final String actorId;
  final String actorName;
  final UserRole actorRole;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  const AuditEventModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor_id': actorId,
        'actor_name': actorName,
        'actor_role': actorRole.name,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      actorName: json['actor_name'] as String? ?? 'System',
      actorRole: UserRole.values.firstWhere(
        (r) => r.name == json['actor_role'],
        orElse: () => UserRole.customer,
      ),
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
