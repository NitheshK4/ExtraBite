import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pg_profile.dart';
import '../models/admin_activity_item.dart';
import '../models/user_model.dart';
import '../models/admin_food_listing.dart';
import '../models/admin_reservation.dart';
import '../models/admin_report.dart';
import '../models/analytics_data.dart';
import 'auth_provider.dart';

class AdminState {
  final Map<String, int> stats;
  final List<PgProfile> pendingProfiles;
  final List<AdminActivityItem> recentActivities;
  final List<UserModel> users;
  final List<AdminFoodListing> foodListings;
  final List<AdminReservation> reservations;
  final List<AdminReport> reports;
  final AnalyticsData? analytics;

  final String searchQuery;
  final PgProfile? selectedProfile;
  final bool isLoading;
  final String? errorMessage;
  final DateTime lastSyncedAt;
  final bool isConnected;

  AdminState({
    required this.stats,
    required this.pendingProfiles,
    required this.recentActivities,
    this.users = const [],
    this.foodListings = const [],
    this.reservations = const [],
    this.reports = const [],
    this.analytics,
    this.searchQuery = '',
    this.selectedProfile,
    this.isLoading = false,
    this.errorMessage,
    DateTime? lastSyncedAt,
    this.isConnected = true,
  }) : lastSyncedAt = lastSyncedAt ?? DateTime.now();

  factory AdminState.initial() => AdminState(
        stats: const {
          'totalUsers': 0,
          'pgOwners': 0,
          'pendingPgs': 0,
          'approvedPgs': 0,
          'foodListings': 0,
          'reservations': 0,
          'rescuedPortions': 0,
        },
        pendingProfiles: const [],
        recentActivities: const [],
        users: const [],
        foodListings: const [],
        reservations: const [],
        reports: const [],
        analytics: AnalyticsData.empty(),
        searchQuery: '',
      );

  List<PgProfile> get filteredPendingProfiles {
    if (searchQuery.trim().isEmpty) return pendingProfiles;
    final q = searchQuery.toLowerCase().trim();
    return pendingProfiles.where((p) {
      final name = p.pgName.toLowerCase();
      final city = p.city.toLowerCase();
      final neighborhood = p.neighborhood.toLowerCase();
      final owner = (p.ownerName ?? '').toLowerCase();
      final phone = p.contactPhone.toLowerCase();
      return name.contains(q) || city.contains(q) || neighborhood.contains(q) || owner.contains(q) || phone.contains(q);
    }).toList();
  }

  List<AdminActivityItem> get filteredActivities {
    if (searchQuery.trim().isEmpty) return recentActivities;
    final q = searchQuery.toLowerCase().trim();
    return recentActivities.where((a) {
      final title = a.title.toLowerCase();
      final sub = a.subtitle.toLowerCase();
      final meta = a.metadata.toLowerCase();
      return title.contains(q) || sub.contains(q) || meta.contains(q);
    }).toList();
  }

  List<UserModel> get filteredUsers {
    if (searchQuery.trim().isEmpty) return users;
    final q = searchQuery.toLowerCase().trim();
    return users.where((u) {
      final name = u.name.toLowerCase();
      final email = u.email.toLowerCase();
      final phone = u.phone.toLowerCase();
      final prop = (u.propertyName ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q) || prop.contains(q);
    }).toList();
  }

  List<AdminFoodListing> get filteredFoodListings {
    if (searchQuery.trim().isEmpty) return foodListings;
    final q = searchQuery.toLowerCase().trim();
    return foodListings.where((f) {
      final title = f.title.toLowerCase();
      final pg = f.pgName.toLowerCase();
      final owner = f.ownerName.toLowerCase();
      final cat = f.category.toLowerCase();
      return title.contains(q) || pg.contains(q) || owner.contains(q) || cat.contains(q);
    }).toList();
  }

  List<AdminReservation> get filteredReservations {
    if (searchQuery.trim().isEmpty) return reservations;
    final q = searchQuery.toLowerCase().trim();
    return reservations.where((r) {
      final ref = r.readableId.toLowerCase();
      final food = r.foodTitle.toLowerCase();
      final cust = r.customerName.toLowerCase();
      final email = r.customerEmail.toLowerCase();
      final pg = r.pgName.toLowerCase();
      return ref.contains(q) || food.contains(q) || cust.contains(q) || email.contains(q) || pg.contains(q);
    }).toList();
  }

  List<AdminReport> get filteredReports {
    if (searchQuery.trim().isEmpty) return reports;
    final q = searchQuery.toLowerCase().trim();
    return reports.where((r) {
      final reason = r.reason.toLowerCase();
      final rep = r.reporterName.toLowerCase();
      final email = r.reporterEmail.toLowerCase();
      final listing = (r.listingTitle ?? '').toLowerCase();
      final pg = (r.pgName ?? '').toLowerCase();
      return reason.contains(q) || rep.contains(q) || email.contains(q) || listing.contains(q) || pg.contains(q);
    }).toList();
  }

  AdminState copyWith({
    Map<String, int>? stats,
    List<PgProfile>? pendingProfiles,
    List<AdminActivityItem>? recentActivities,
    List<UserModel>? users,
    List<AdminFoodListing>? foodListings,
    List<AdminReservation>? reservations,
    List<AdminReport>? reports,
    AnalyticsData? analytics,
    String? searchQuery,
    PgProfile? selectedProfile,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool? isConnected,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      pendingProfiles: pendingProfiles ?? this.pendingProfiles,
      recentActivities: recentActivities ?? this.recentActivities,
      users: users ?? this.users,
      foodListings: foodListings ?? this.foodListings,
      reservations: reservations ?? this.reservations,
      reports: reports ?? this.reports,
      analytics: analytics ?? this.analytics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final Ref _ref;

  AdminNotifier(this._ref) : super(AdminState.initial());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final stats = await repo.getDashboardStats();
      final pending = await repo.getPendingPgProfiles();
      final activities = await repo.getRecentActivities();
      state = state.copyWith(
        stats: stats,
        pendingProfiles: pending,
        recentActivities: activities,
        isLoading: false,
        lastSyncedAt: DateTime.now(),
        isConnected: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data: $e',
        isConnected: false,
      );
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final list = await repo.getAllUsers();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load users: $e');
    }
  }

  Future<bool> toggleUserSuspension(String userId, bool isSuspended) async {
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.toggleUserSuspension(userId, isSuspended);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update user status: $e');
      return false;
    }
  }

  Future<void> loadFoodListings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final list = await repo.getAllFoodListings();
      state = state.copyWith(foodListings: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load food listings: $e');
    }
  }

  Future<bool> updateListingStatus(String listingId, String newStatus) async {
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.updateListingStatus(listingId, newStatus);
      await loadFoodListings();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update listing: $e');
      return false;
    }
  }

  Future<void> loadReservations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final list = await repo.getAllReservations();
      state = state.copyWith(reservations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load reservations: $e');
    }
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final list = await repo.getAllReports();
      state = state.copyWith(reports: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load reports: $e');
    }
  }

  Future<bool> resolveReport(String reportId, String status, String adminNotes) async {
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.resolveReport(reportId, status, adminNotes);
      await loadReports();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to resolve report: $e');
      return false;
    }
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final data = await repo.getAnalyticsData();
      state = state.copyWith(analytics: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load analytics: $e');
    }
  }

  Future<void> selectProfileById(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final profile = await repo.getPgProfile(id);
      state = state.copyWith(
        selectedProfile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch PG details: $e',
      );
    }
  }

  Future<bool> approveProfile(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.approvePgProfile(id);
      await loadDashboardData();
      if (state.selectedProfile?.id == id) {
        state = state.copyWith(selectedProfile: null);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Approval failed: $e',
      );
      return false;
    }
  }

  Future<bool> rejectProfile(String id, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.rejectPgProfile(id, reason);
      await loadDashboardData();
      if (state.selectedProfile?.id == id) {
        state = state.copyWith(selectedProfile: null);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Rejection failed: $e',
      );
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});
