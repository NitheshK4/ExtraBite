import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pg_profile.dart';
import '../../models/admin_activity_item.dart';
import '../../models/user_model.dart';
import '../../models/admin_food_listing.dart';
import '../../models/admin_reservation.dart';
import '../../models/admin_report.dart';
import '../../models/analytics_data.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  /// Logs out the current admin session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetches real-time counts from the database tables for the dashboard.
  Future<Map<String, int>> getDashboardStats() async {
    try {
      // 1. Total Users
      final usersRes = await _client.from('profiles').select('id');
      final totalUsers = (usersRes as List).length;

      // 2. PG Owners
      final ownersRes = await _client.from('profiles').select('id').eq('role', 'pg_owner');
      final pgOwners = (ownersRes as List).length;

      // 3. Pending PG Properties (is_approved = false and not rejected)
      final pendingRes = await _client
          .from('pg_profiles')
          .select('id, is_rejected')
          .eq('is_approved', false);
      
      final pendingList = pendingRes as List<dynamic>;
      final pendingPgs = pendingList.where((p) => (p['is_rejected'] as bool? ?? false) == false).length;

      // 4. Approved PG Properties
      final approvedRes = await _client.from('pg_profiles').select('id').eq('is_approved', true);
      final approvedPgs = (approvedRes as List).length;

      // 5. Active Food Listings
      final listingsRes = await _client.from('food_listings').select('id, status').neq('status', 'removed');
      final foodListings = (listingsRes as List).length;

      // 6. Reservations Total & Rescued Portions
      final reservationsRes = await _client.from('reservations').select('id, portions_count, status');
      final resList = reservationsRes as List<dynamic>;
      final reservations = resList.length;

      int rescuedPortions = 0;
      for (final r in resList) {
        final status = (r['status'] as String? ?? '').toLowerCase();
        if (status == 'picked_up' || status == 'completed') {
          rescuedPortions += (r['portions_count'] as num? ?? 1).toInt();
        }
      }

      return {
        'totalUsers': totalUsers,
        'pgOwners': pgOwners,
        'pendingPgs': pendingPgs,
        'approvedPgs': approvedPgs,
        'foodListings': foodListings,
        'reservations': reservations,
        'rescuedPortions': rescuedPortions,
      };
    } catch (_) {
      return {
        'totalUsers': 0,
        'pgOwners': 0,
        'pendingPgs': 0,
        'approvedPgs': 0,
        'foodListings': 0,
        'reservations': 0,
        'rescuedPortions': 0,
      };
    }
  }

  /// Fetches all pg_profiles that require verification (is_approved = false).
  Future<List<PgProfile>> getPendingPgProfiles() async {
    try {
      final response = await _client
          .from('pg_profiles')
          .select('*, profiles(full_name, email)')
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((e) => PgProfile.fromJson(e as Map<String, dynamic>))
          .where((p) => !p.isApproved)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches recent live surplus activity directly from real food listings and reservations.
  Future<List<AdminActivityItem>> getRecentActivities() async {
    try {
      final List<AdminActivityItem> activities = [];

      // 1. Fetch recent food listings
      try {
        final listingsRes = await _client
            .from('food_listings')
            .select('id, title, total_portions, available_portions, pickup_end_time, created_at, pg_profiles(pg_name)')
            .order('created_at', ascending: false)
            .limit(6);

        for (final row in listingsRes as List<dynamic>) {
          final pg = row['pg_profiles'] as Map<String, dynamic>?;
          final pgName = pg != null ? (pg['pg_name'] as String? ?? 'Hostel Mess') : 'Hostel Mess';
          final portions = row['total_portions'] ?? row['available_portions'] ?? 1;
          final createdAt = row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : DateTime.now();
          final pickupEnd = row['pickup_end_time'] != null ? DateTime.tryParse(row['pickup_end_time'] as String) : null;
          final expiresStr = pickupEnd != null ? 'Expires in ${pickupEnd.difference(DateTime.now()).inHours.clamp(1, 24)}h' : 'Available today';

          activities.add(AdminActivityItem(
            id: row['id'] as String,
            type: ActivityType.newListing,
            title: '${portions}x ${row['title'] ?? 'Surplus Meal'} Portions',
            subtitle: pgName,
            metadata: expiresStr,
            timestamp: createdAt,
            statusLabel: 'Active',
          ));
        }
      } catch (_) {}

      // 2. Fetch recent reservations
      try {
        final resRes = await _client
            .from('reservations')
            .select('id, status, created_at, portions_count, food_listings(title), profiles(email, full_name)')
            .order('created_at', ascending: false)
            .limit(6);

        for (final row in resRes as List<dynamic>) {
          final food = row['food_listings'] as Map<String, dynamic>?;
          final foodTitle = food != null ? (food['title'] as String? ?? 'Surplus Food') : 'Surplus Food';
          final profile = row['profiles'] as Map<String, dynamic>?;
          final userEmail = profile != null ? (profile['email'] as String? ?? 'Student') : 'Student';
          final createdAt = row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : DateTime.now();
          final statusStr = (row['status'] as String? ?? 'confirmed').toLowerCase();
          final isCompleted = statusStr == 'picked_up' || statusStr == 'completed';

          activities.add(AdminActivityItem(
            id: row['id'] as String,
            type: isCompleted ? ActivityType.pickupCompleted : ActivityType.reservationConfirmed,
            title: isCompleted ? 'Pickup Completed' : 'Reservation Confirmed',
            subtitle: '#EB-${row['id'].toString().substring(0, row['id'].toString().length > 6 ? 6 : row['id'].toString().length).toUpperCase()} • $foodTitle',
            metadata: 'User: $userEmail',
            timestamp: createdAt,
            statusLabel: isCompleted ? 'Completed' : 'Reserved',
          ));
        }
      } catch (_) {}

      // Sort by timestamp descending
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(8).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches details for a specific PG profile.
  Future<PgProfile?> getPgProfile(String id) async {
    try {
      final response = await _client
          .from('pg_profiles')
          .select('*, profiles(full_name, email)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return PgProfile.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Approves a PG property by updating is_approved to true.
  Future<void> approvePgProfile(String id) async {
    await _client
        .from('pg_profiles')
        .update({
          'is_approved': true,
          'is_active': true,
          'is_rejected': false,
          'rejection_reason': null,
        })
        .eq('id', id);
  }

  /// Rejects a PG property with an admin explanation reason.
  Future<void> rejectPgProfile(String id, String reason) async {
    await _client
        .from('pg_profiles')
        .update({
          'is_approved': false,
          'is_active': false,
          'is_rejected': true,
          'rejection_reason': reason,
        })
        .eq('id', id);
  }

  // ===========================================================================
  // User Management
  // ===========================================================================
  Future<List<UserModel>> getAllUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select('*, pg_profiles(pg_name)')
          .order('created_at', ascending: false);
      return (res as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleUserSuspension(String userId, bool isSuspended) async {
    await _client.from('profiles').update({'is_suspended': isSuspended}).eq('id', userId);
  }

  // ===========================================================================
  // Food Listings
  // ===========================================================================
  Future<List<AdminFoodListing>> getAllFoodListings() async {
    try {
      final res = await _client
          .from('food_listings')
          .select('*, pg_profiles(pg_name, owner_id, profiles(full_name))')
          .order('created_at', ascending: false);
      return (res as List).map((e) => AdminFoodListing.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateListingStatus(String listingId, String newStatus) async {
    await _client.from('food_listings').update({'status': newStatus}).eq('id', listingId);
  }

  // ===========================================================================
  // Reservations Feed
  // ===========================================================================
  Future<List<AdminReservation>> getAllReservations() async {
    try {
      final res = await _client
          .from('reservations')
          .select('*, food_listings(title, discounted_price, pg_profiles(pg_name)), profiles(full_name, email, phone_number)')
          .order('created_at', ascending: false);
      return (res as List).map((e) => AdminReservation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // Safety & Reports
  // ===========================================================================
  Future<List<AdminReport>> getAllReports() async {
    try {
      final res = await _client
          .from('listing_reports')
          .select('*, profiles(full_name, email), food_listings(title), pg_profiles(pg_name)')
          .order('created_at', ascending: false);
      return (res as List).map((e) => AdminReport.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> resolveReport(String reportId, String status, String adminNotes) async {
    await _client.from('listing_reports').update({
      'status': status,
      'admin_notes': adminNotes,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  // ===========================================================================
  // Analytics & Impact
  // ===========================================================================
  Future<AnalyticsData> getAnalyticsData() async {
    try {
      final usersRes = await _client.from('profiles').select('id, role');
      final usersList = usersRes as List<dynamic>;
      final totalUsers = usersList.length;
      final totalCustomers = usersList.where((u) => (u['role'] as String? ?? '').toLowerCase() == 'customer').length;
      final totalPgOwners = usersList.where((u) => (u['role'] as String? ?? '').toLowerCase() == 'pg_owner').length;
      final totalAdmins = usersList.where((u) => (u['role'] as String? ?? '').toLowerCase() == 'admin').length;

      final pgsRes = await _client.from('pg_profiles').select('id, is_approved');
      final pgsList = pgsRes as List<dynamic>;
      final verifiedPgs = pgsList.where((p) => (p['is_approved'] as bool? ?? false) == true).length;
      final pendingPgs = pgsList.where((p) => (p['is_approved'] as bool? ?? false) == false).length;

      final foodRes = await _client.from('food_listings').select('id, status');
      final foodList = foodRes as List<dynamic>;
      final totalFoodListings = foodList.length;
      final activeFoodListings = foodList.where((f) => (f['status'] as String? ?? '').toLowerCase() == 'active').length;

      final resRes = await _client.from('reservations').select('id, portions_count, total_amount, status');
      final resList = resRes as List<dynamic>;
      final totalReservations = resList.length;

      int completedPickups = 0;
      int cancelledReservations = 0;
      int rescuedPortions = 0;
      double totalFoodValueRescued = 0.0;

      for (final r in resList) {
        final status = (r['status'] as String? ?? '').toLowerCase();
        if (status == 'picked_up' || status == 'completed') {
          completedPickups++;
          final portions = (r['portions_count'] as num? ?? 1).toInt();
          rescuedPortions += portions;
          totalFoodValueRescued += (r['total_amount'] as num? ?? 0.0).toDouble();
        } else if (status == 'cancelled') {
          cancelledReservations++;
        }
      }

      final completionRate = totalReservations > 0 ? (completedPickups / totalReservations) * 100 : 0.0;

      return AnalyticsData(
        totalUsers: totalUsers,
        totalCustomers: totalCustomers,
        totalPgOwners: totalPgOwners,
        totalAdmins: totalAdmins,
        verifiedPgs: verifiedPgs,
        pendingPgs: pendingPgs,
        totalFoodListings: totalFoodListings,
        activeFoodListings: activeFoodListings,
        totalReservations: totalReservations,
        completedPickups: completedPickups,
        cancelledReservations: cancelledReservations,
        rescuedPortions: rescuedPortions,
        totalFoodValueRescued: totalFoodValueRescued,
        completionRate: completionRate,
      );
    } catch (_) {
      return AnalyticsData.empty();
    }
  }
}
