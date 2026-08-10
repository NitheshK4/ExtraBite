import 'package:flutter/material.dart';

class DistanceBadge extends StatelessWidget {
  final double distanceKm;
  final bool isCompact;

  const DistanceBadge({
    super.key,
    required this.distanceKm,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext meContext) {
    final isVeryClose = distanceKm <= 1.0;
    final isWithinDefaultRadius = distanceKm <= 2.0;

    final Color bgColor = isVeryClose
        ? const Color(0xFFE8F5E9)
        : (isWithinDefaultRadius
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFFFF3E0));

    final Color textColor = isVeryClose
        ? const Color(0xFF2E7D32)
        : (isWithinDefaultRadius
            ? const Color(0xFF1565C0)
            : const Color(0xFFE65100));

    final String distanceStr = distanceKm < 1.0
        ? '${(distanceKm * 1000).toInt()} m away'
        : '${distanceKm.toStringAsFixed(1)} km away';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            size: isCompact ? 12 : 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            distanceStr,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
