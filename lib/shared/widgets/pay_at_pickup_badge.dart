import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class PayAtPickupBadge extends StatelessWidget {
  final bool isCompact;
  final bool showDescription;

  const PayAtPickupBadge({
    super.key,
    this.isCompact = false,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.payAtPickupBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.payAtPickupBorder, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 13,
              color: AppColors.payAtPickupText,
            ),
            SizedBox(width: 4),
            Text(
              AppConstants.paymentMethodLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.payAtPickupText,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.payAtPickupBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.payAtPickupBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 18,
                color: AppColors.payAtPickupText,
              ),
              SizedBox(width: 8),
              Text(
                AppConstants.paymentMethodLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.payAtPickupText,
                ),
              ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 4),
            const Text(
              AppConstants.paymentInstruction,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
