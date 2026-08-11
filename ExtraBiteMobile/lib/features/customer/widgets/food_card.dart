import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../models/food_listing.dart';

class FoodCard extends StatelessWidget {
  final FoodListing food;
  final VoidCallback onTap;

  const FoodCard({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatTime = DateFormat('hh:mm a');
    final pickupWindowStr = '${formatTime.format(food.pickupStarts)} - ${formatTime.format(food.pickupEnds)}';
    
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image + Badges
            Stack(
              children: [
                // Premium Colored Placeholder Container for Food Image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      food.isVegetarian ? Icons.eco : Icons.kebab_dining,
                      size: 64,
                      color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                    ),
                  ),
                ),
                
                // Discount Badge
                if (food.discountPercentage > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${food.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Distance Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${food.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Veg / Non-Veg Indicator
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          food.isVegetarian ? 'VEG' : 'NON-VEG',
                          style: TextStyle(
                            color: food.isVegetarian ? AppColors.vegColor : AppColors.nonVegColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.foodName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Availability Count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: food.availablePortions <= 3 
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${food.availablePortions} left',
                          style: TextStyle(
                            color: food.availablePortions <= 3 
                                ? AppColors.error 
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Property Name & Location
                  Row(
                    children: [
                      Text(
                        food.propertyName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: AppColors.textLight)),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          food.locationAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  
                  // Bottom Pricing & Window row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Row(
                        children: [
                          Text(
                            '₹${food.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${food.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      
                      // Pickup window info
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: food.isExpired 
                                ? AppColors.error 
                                : (food.isPickupActive ? AppColors.success : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            food.isExpired 
                                ? 'Expired' 
                                : pickupWindowStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: food.isExpired 
                                  ? AppColors.error 
                                  : (food.isPickupActive ? AppColors.success : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
