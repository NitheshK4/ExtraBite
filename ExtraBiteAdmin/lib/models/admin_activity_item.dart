enum ActivityType {
  newListing,
  reservationConfirmed,
  pickupCompleted,
}

class AdminActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final String metadata;
  final DateTime timestamp;
  final String? statusLabel;

  AdminActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metadata,
    required this.timestamp,
    this.statusLabel,
  });

  String get relativeTimeString {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }
}
