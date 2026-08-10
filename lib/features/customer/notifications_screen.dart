import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Dinner Pickup Window Open',
        'body': 'Sri Sai Executive PG just opened pickup for 8 portions of South Indian Thali.',
        'time': '10 mins ago',
        'icon': Icons.notifications_active_rounded,
      },
      {
        'title': 'Reservation Confirmed',
        'body': 'Your reservation EB-84921 has been acknowledged. Remember: Pay at pickup.',
        'time': '25 mins ago',
        'icon': Icons.check_circle_rounded,
      },
      {
        'title': 'Surplus Alert near HSR Layout',
        'body': 'TechPark Scholars Hostel added fresh Dal Tadka at 60% discount.',
        'time': '2 hours ago',
        'icon': Icons.local_offer_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(item['icon'] as IconData, color: AppColors.primary),
            ),
            title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(item['body'] as String),
                const SizedBox(height: 4),
                Text(item['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
