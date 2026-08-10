import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_listing_model.dart';

class DietaryChip extends StatelessWidget {
  final DietaryType dietaryType;

  const DietaryChip({
    super.key,
    required this.dietaryType,
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData iconData;

    switch (dietaryType) {
      case DietaryType.vegetarian:
        chipColor = AppColors.veg;
        iconData = Icons.eco_rounded;
        break;
      case DietaryType.nonVegetarian:
        chipColor = AppColors.nonVeg;
        iconData = Icons.restaurant_rounded;
        break;
      case DietaryType.vegan:
        chipColor = AppColors.vegan;
        iconData = Icons.spa_rounded;
        break;
      case DietaryType.egg:
        chipColor = AppColors.egg;
        iconData = Icons.egg_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            dietaryType.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
