import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

enum StatusType {
  active,
  endingSoon,
  soldOut,
  expired,
  confirmed,
  ready,
  completed,
  cancelled,
  pending,
  approved,
  rejected,
}

class StatusBadge extends StatelessWidget {
  final StatusType type;
  final String? customLabel;
  final IconData? customIcon;

  const StatusBadge({
    super.key,
    required this.type,
    this.customLabel,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;
    String label;

    switch (type) {
      case StatusType.active:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        border = AppColors.primary.withOpacity(0.2);
        icon = Icons.check_circle_outline;
        label = 'Active';
        break;
      case StatusType.endingSoon:
        bg = AppColors.secondaryLight;
        fg = AppColors.secondary;
        border = AppColors.secondary.withOpacity(0.3);
        icon = Icons.timer_outlined;
        label = 'Ending Soon';
        break;
      case StatusType.soldOut:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        border = AppColors.error.withOpacity(0.3);
        icon = Icons.block;
        label = 'Sold Out';
        break;
      case StatusType.expired:
        bg = AppColors.surfaceDim;
        fg = AppColors.textLight;
        border = AppColors.border;
        icon = Icons.hourglass_disabled;
        label = 'Expired';
        break;
      case StatusType.confirmed:
        bg = AppColors.secondaryLight;
        fg = AppColors.secondary;
        border = AppColors.secondary.withOpacity(0.3);
        icon = Icons.receipt_long;
        label = 'Confirmed';
        break;
      case StatusType.ready:
        bg = AppColors.tertiaryLight;
        fg = AppColors.tertiary;
        border = AppColors.tertiary.withOpacity(0.3);
        icon = Icons.notifications_active_outlined;
        label = 'Ready for Pickup';
        break;
      case StatusType.completed:
        bg = AppColors.primaryLight;
        fg = AppColors.success;
        border = AppColors.success.withOpacity(0.3);
        icon = Icons.task_alt;
        label = 'Completed';
        break;
      case StatusType.cancelled:
        bg = AppColors.surfaceDim;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      case StatusType.pending:
        bg = AppColors.secondaryLight;
        fg = AppColors.secondary;
        border = AppColors.secondary.withOpacity(0.3);
        icon = Icons.hourglass_top;
        label = 'Under Review';
        break;
      case StatusType.approved:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        border = AppColors.primary.withOpacity(0.3);
        icon = Icons.verified_user_outlined;
        label = 'Approved & Active';
        break;
      case StatusType.rejected:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        border = AppColors.error.withOpacity(0.3);
        icon = Icons.error_outline;
        label = 'Action Required';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(customIcon ?? icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            customLabel ?? label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
