class AdminReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final String? listingId;
  final String? listingTitle;
  final String? pgId;
  final String? pgName;
  final String reason;
  final String? description;
  final String? imageEvidenceUrl;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  AdminReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    this.listingId,
    this.listingTitle,
    this.pgId,
    this.pgName,
    required this.reason,
    this.description,
    this.imageEvidenceUrl,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final reporter = json['profiles'] as Map<String, dynamic>?;
    final reporterName = reporter != null ? (reporter['full_name'] as String? ?? 'Reporter') : 'Reporter';
    final reporterEmail = reporter != null ? (reporter['email'] as String? ?? '') : '';

    final listing = json['food_listings'] as Map<String, dynamic>?;
    final listingTitle = listing != null ? listing['title'] as String? : null;

    final pg = json['pg_profiles'] as Map<String, dynamic>?;
    final pgName = pg != null ? pg['pg_name'] as String? : null;

    return AdminReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String? ?? '',
      reporterName: reporterName,
      reporterEmail: reporterEmail,
      listingId: json['listing_id'] as String?,
      listingTitle: listingTitle,
      pgId: json['pg_id'] as String?,
      pgName: pgName,
      reason: json['reason'] as String? ?? 'Quality or Safety Concern',
      description: json['description'] as String?,
      imageEvidenceUrl: json['image_evidence_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
    );
  }
}
