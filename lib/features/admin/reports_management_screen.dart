import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/report_model.dart';
import '../../shared/widgets/empty_state_view.dart';

class ReportsManagementScreen extends ConsumerWidget {
  const ReportsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Disputes'),
      ),
      body: reports.isEmpty
          ? EmptyStateView(
              icon: Icons.check_circle_outline_rounded,
              title: 'No pending reports',
              subtitle: 'All customer and hostel inquiries have been resolved.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final rep = reports[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rep.reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                            Text(
                              rep.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rep.status == 'pending' ? Colors.orange.shade800 : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rep.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Target: ${rep.listingTitle ?? rep.pgName ?? 'PG Entity'}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Reported by: ${rep.reporterName} • ${DateTimeUtils.formatDateTime(rep.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        if (rep.status == 'pending') ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  ref.read(reportProvider.notifier).dismissReport(rep.id, 'Dismissed as false report');
                                },
                                child: const Text('Dismiss'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                                onPressed: () {
                                  ref.read(reportProvider.notifier).resolveReport(rep.id, 'Listing updated by admin');
                                },
                                child: const Text('Resolve & Close'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
