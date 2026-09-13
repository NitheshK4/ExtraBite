import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_history_item.dart';
import 'auth_provider.dart';

/// Catalog of known campuses, towns, and landmarks in the region used for search autocomplete.
/// Note: These are NOT default history entries. They are only suggestions when the user types in search.
final List<LocationHistoryItem> knownLocationsCatalog = [
  LocationHistoryItem(
    id: 'vit_ap',
    title: 'Near VIT-AP University',
    subtitle: 'Inavolu, Amaravati, Andhra Pradesh',
    latitude: 16.4971,
    longitude: 80.5005,
    icon: 'campus',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'srm_ap',
    title: 'Near SRM University-AP',
    subtitle: 'Neerukonda, Mangalagiri, Andhra Pradesh',
    latitude: 16.4710,
    longitude: 80.5100,
    icon: 'campus',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'thullur',
    title: 'Thullur Center',
    subtitle: 'Capital Region, Amaravati',
    latitude: 16.5300,
    longitude: 80.4700,
    icon: 'town',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'mangalagiri',
    title: 'Mangalagiri Town',
    subtitle: 'Near Highway Junction, Guntur',
    latitude: 16.4300,
    longitude: 80.5600,
    icon: 'town',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'benz_circle',
    title: 'Vijayawada Benz Circle',
    subtitle: 'MG Road / Benz Circle area',
    latitude: 16.5000,
    longitude: 80.6400,
    icon: 'city',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'guntur_center',
    title: 'Guntur Collectorate / Center',
    subtitle: 'Guntur City, Andhra Pradesh',
    latitude: 16.3067,
    longitude: 80.4365,
    icon: 'city',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'tadepalli',
    title: 'Tadepalli Bypass',
    subtitle: 'Amaravati Gateway, Guntur',
    latitude: 16.4800,
    longitude: 80.6000,
    icon: 'town',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'mandadam',
    title: 'Mandadam Village',
    subtitle: 'Secretariat Road, Amaravati',
    latitude: 16.5150,
    longitude: 80.5300,
    icon: 'town',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
  LocationHistoryItem(
    id: 'undavalli',
    title: 'Undavalli Caves Area',
    subtitle: 'Prakasam Barrage Road, Amaravati',
    latitude: 16.4950,
    longitude: 80.5800,
    icon: 'place',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  ),
];

class LocationHistoryNotifier extends StateNotifier<List<LocationHistoryItem>> {
  String _storageKey;
  SharedPreferences? _prefs;

  LocationHistoryNotifier({
    String? userId,
    SharedPreferences? prefs,
    List<LocationHistoryItem> initialHistory = const [],
  })  : _prefs = prefs,
        _storageKey = _computeStorageKey(userId),
        super(initialHistory) {
    _init();
  }

  static String _computeStorageKey(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      return 'extrabite_location_history_$userId';
    }
    return 'extrabite_location_history_guest';
  }

  Future<void> _init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await loadHistory();
    } catch (_) {
      // Graceful fallback for test or mock environments
    }
  }

  Future<void> loadHistory() async {
    if (_prefs == null) return;
    final rawList = _prefs!.getStringList(_storageKey);
    if (rawList != null && rawList.isNotEmpty) {
      final items = <LocationHistoryItem>[];
      for (final jsonStr in rawList) {
        try {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          items.add(LocationHistoryItem.fromMap(decoded));
        } catch (_) {}
      }
      state = items;
    } else {
      state = const [];
    }
  }

  /// Adds a location to history.
  /// If it already exists, removes the older entry and moves it to the top.
  /// Deduplication is based on normalized title or coordinates.
  Future<void> addLocation(LocationHistoryItem item) async {
    final now = DateTime.now();
    final updatedItem = item.copyWith(timestamp: now);

    final filtered = state.where((existing) {
      final sameTitle = existing.title.trim().toLowerCase() ==
          updatedItem.title.trim().toLowerCase();
      final sameCoords =
          (existing.latitude - updatedItem.latitude).abs() < 0.0001 &&
              (existing.longitude - updatedItem.longitude).abs() < 0.0001;
      return !sameTitle && !sameCoords;
    }).toList();

    final newList = [updatedItem, ...filtered];
    if (newList.length > 20) {
      newList.removeRange(20, newList.length);
    }

    state = newList;
    await _persist();
  }

  Future<void> removeLocation(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> clearHistory() async {
    state = const [];
    if (_prefs != null) {
      await _prefs!.remove(_storageKey);
    }
  }

  Future<void> switchUser(String? userId) async {
    _storageKey = _computeStorageKey(userId);
    await loadHistory();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final stringList = state.map((item) => json.encode(item.toMap())).toList();
    await _prefs!.setStringList(_storageKey, stringList);
  }
}

final locationHistoryProvider =
    StateNotifierProvider<LocationHistoryNotifier, List<LocationHistoryItem>>(
        (ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return LocationHistoryNotifier(userId: userId);
});
