class LocationHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String icon; // 'campus', 'town', 'city', 'place'
  final DateTime timestamp;

  LocationHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.icon = 'place',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  LocationHistoryItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? latitude,
    double? longitude,
    String? icon,
    DateTime? timestamp,
  }) {
    return LocationHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationHistoryItem.fromMap(Map<String, dynamic> map) {
    return LocationHistoryItem(
      id: map['id'] as String? ?? (map['title'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 16.4971,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 80.5005,
      icon: map['icon'] as String? ?? 'place',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationHistoryItem &&
          runtimeType == other.runtimeType &&
          (id == other.id ||
              (title.trim().toLowerCase() == other.title.trim().toLowerCase() &&
                  (latitude - other.latitude).abs() < 0.0001 &&
                  (longitude - other.longitude).abs() < 0.0001));

  @override
  int get hashCode =>
      title.trim().toLowerCase().hashCode ^
      (latitude * 1000).round().hashCode ^
      (longitude * 1000).round().hashCode;
}
