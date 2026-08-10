import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_listing_model.dart';
import '../../models/reservation_model.dart';
import 'listing_repository.dart';
import 'reservation_repository.dart';
import 'report_repository.dart';

class OwnerAnalyticsSummary {
  final int activeListingsCount;
  final int availablePortionsCount;
  final int pendingReservationsCount;
  final int completedPickupsCount;
  final double estimatedRevenueCollected;
  final int mealsRescuedCount;
  final double foodWasteAvoidedKg;

  const OwnerAnalyticsSummary({
    required this.activeListingsCount,
    required this.availablePortionsCount,
    required this.pendingReservationsCount,
    required this.completedPickupsCount,
    required this.estimatedRevenueCollected,
    required this.mealsRescuedCount,
    required this.foodWasteAvoidedKg,
  });
}

class AdminMarketplaceSummary {
  final int totalListings;
  final int activeListings;
  final int totalReservations;
  final int totalMealsRescued;
  final double totalValueCollectedAtPickup;
  final int pendingReportsCount;
  final double foodWasteDivertedKg;

  const AdminMarketplaceSummary({
    required this.totalListings,
    required this.activeListings,
    required this.totalReservations,
    required this.totalMealsRescued,
    required this.totalValueCollectedAtPickup,
    required this.pendingReportsCount,
    required this.foodWasteDivertedKg,
  });
}

final ownerAnalyticsProvider = Provider.family<OwnerAnalyticsSummary, String>((ref, pgId) {
  final listings = ref.watch(listingProvider).where((l) => l.pgId == pgId).toList();
  final reservations = ref.watch(reservationProvider).where((r) => r.pgId == pgId).toList();

  final activeListings = listings.where((l) => l.status == ListingStatus.active).length;
  final availablePortions = listings
      .where((l) => l.status == ListingStatus.active)
      .fold<int>(0, (sum, item) => sum + item.availablePortions);

  final pendingReservations = reservations.where((r) => r.status.isActive).length;
  final completedPickups = reservations.where((r) => r.status == ReservationStatus.pickedUp).toList();

  final revenueCollected = completedPickups.fold<double>(
    0.0,
    (sum, item) => sum + item.totalAmount,
  );

  final mealsRescued = completedPickups.fold<int>(
    0,
    (sum, item) => sum + item.portionsCount,
  );

  final wasteAvoidedKg = mealsRescued * 0.45; // ~450g per meal

  return OwnerAnalyticsSummary(
    activeListingsCount: activeListings,
    availablePortionsCount: availablePortions,
    pendingReservationsCount: pendingReservations,
    completedPickupsCount: completedPickups.length,
    estimatedRevenueCollected: revenueCollected,
    mealsRescuedCount: mealsRescued,
    foodWasteAvoidedKg: wasteAvoidedKg,
  );
});

final adminAnalyticsProvider = Provider<AdminMarketplaceSummary>((ref) {
  final listings = ref.watch(listingProvider);
  final reservations = ref.watch(reservationProvider);
  final reports = ref.watch(reportProvider);

  final active = listings.where((l) => l.status == ListingStatus.active).length;
  final completed = reservations.where((r) => r.status == ReservationStatus.pickedUp).toList();

  final revenue = completed.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
  final meals = completed.fold<int>(0, (sum, r) => sum + r.portionsCount);
  final pendingReports = reports.where((r) => r.status == 'pending').length;

  return AdminMarketplaceSummary(
    totalListings: listings.length,
    activeListings: active,
    totalReservations: reservations.length,
    totalMealsRescued: meals,
    totalValueCollectedAtPickup: revenue,
    pendingReportsCount: pendingReports,
    foodWasteDivertedKg: meals * 0.45,
  );
});
