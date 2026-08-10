import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/reservation_model.dart';
import '../../models/food_listing_model.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  factory StatusBadge.fromReservationStatus(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return const StatusBadge(
          text: 'Confirmed',
          color: AppColors.statusPending,
          icon: Icons.access_time_filled_rounded,
        );
      case ReservationStatus.readyForPickup:
        return const StatusBadge(
          text: 'Ready for Pickup',
          color: AppColors.statusReady,
          icon: Icons.storefront_rounded,
        );
      case ReservationStatus.pickedUp:
        return const StatusBadge(
          text: 'Picked Up',
          color: AppColors.statusCompleted,
          icon: Icons.check_circle_rounded,
        );
      case ReservationStatus.cancelled:
        return const StatusBadge(
          text: 'Cancelled',
          color: AppColors.statusCancelled,
          icon: Icons.cancel_rounded,
        );
      case ReservationStatus.expired:
        return const StatusBadge(
          text: 'Expired',
          color: AppColors.statusExpired,
          icon: Icons.timer_off_rounded,
        );
      case ReservationStatus.draft:
      case ReservationStatus.noShow:
      case ReservationStatus.rejected:
        return StatusBadge(
          text: status.displayName,
          color: Colors.grey,
        );
    }
  }

  factory StatusBadge.fromListingStatus(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return const StatusBadge(
          text: 'Available Now',
          color: AppColors.statusActive,
          icon: Icons.check_circle_outline_rounded,
        );
      case ListingStatus.paused:
        return const StatusBadge(
          text: 'Paused',
          color: AppColors.statusPending,
          icon: Icons.pause_circle_filled_rounded,
        );
      case ListingStatus.soldOut:
        return const StatusBadge(
          text: 'Sold Out',
          color: AppColors.statusCancelled,
          icon: Icons.do_not_disturb_on_rounded,
        );
      case ListingStatus.expired:
        return const StatusBadge(
          text: 'Closed',
          color: AppColors.statusExpired,
          icon: Icons.history_toggle_off_rounded,
        );
      case ListingStatus.removed:
        return const StatusBadge(
          text: 'Removed',
          color: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
