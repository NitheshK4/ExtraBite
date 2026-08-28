class AnalyticsData {
  final int totalUsers;
  final int totalCustomers;
  final int totalPgOwners;
  final int totalAdmins;
  final int verifiedPgs;
  final int pendingPgs;
  final int totalFoodListings;
  final int activeFoodListings;
  final int totalReservations;
  final int completedPickups;
  final int cancelledReservations;
  final int rescuedPortions;
  final double totalFoodValueRescued;
  final double completionRate;

  AnalyticsData({
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalPgOwners,
    required this.totalAdmins,
    required this.verifiedPgs,
    required this.pendingPgs,
    required this.totalFoodListings,
    required this.activeFoodListings,
    required this.totalReservations,
    required this.completedPickups,
    required this.cancelledReservations,
    required this.rescuedPortions,
    required this.totalFoodValueRescued,
    required this.completionRate,
  });

  factory AnalyticsData.empty() => AnalyticsData(
        totalUsers: 0,
        totalCustomers: 0,
        totalPgOwners: 0,
        totalAdmins: 0,
        verifiedPgs: 0,
        pendingPgs: 0,
        totalFoodListings: 0,
        activeFoodListings: 0,
        totalReservations: 0,
        completedPickups: 0,
        cancelledReservations: 0,
        rescuedPortions: 0,
        totalFoodValueRescued: 0.0,
        completionRate: 0.0,
      );
}
