class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? listingId;
  final String? listingTitle;
  final String? pgId;
  final String? pgName;
  final String reason;
  final String description;
  final String? imageEvidenceUrl;
  final String status; // pending, resolved, dismissed
  final String? adminNotes;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.listingId,
    this.listingTitle,
    this.pgId,
    this.pgName,
    required this.reason,
    required this.description,
    this.imageEvidenceUrl,
    this.status = 'pending',
    this.adminNotes,
    required this.createdAt,
  });

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? listingId,
    String? listingTitle,
    String? pgId,
    String? pgName,
    String? reason,
    String? description,
    String? imageEvidenceUrl,
    String? status,
    String? adminNotes,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      pgId: pgId ?? this.pgId,
      pgName: pgName ?? this.pgName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      imageEvidenceUrl: imageEvidenceUrl ?? this.imageEvidenceUrl,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporter_id': reporterId,
        'reporter_name': reporterName,
        'listing_id': listingId,
        'listing_title': listingTitle,
        'pg_id': pgId,
        'pg_name': pgName,
        'reason': reason,
        'description': description,
        'image_evidence_url': imageEvidenceUrl,
        'status': status,
        'admin_notes': adminNotes,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reporterName: json['reporter_name'] as String? ?? 'User',
      listingId: json['listing_id'] as String?,
      listingTitle: json['listing_title'] as String?,
      pgId: json['pg_id'] as String?,
      pgName: json['pg_name'] as String?,
      reason: json['reason'] as String,
      description: json['description'] as String? ?? '',
      imageEvidenceUrl: json['image_evidence_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
