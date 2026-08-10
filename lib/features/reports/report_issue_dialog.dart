import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/auth_repository.dart';

class ReportIssueDialog extends ConsumerStatefulWidget {
  final String? listingId;
  final String? listingTitle;
  final String? pgId;
  final String? pgName;

  const ReportIssueDialog({
    super.key,
    this.listingId,
    this.listingTitle,
    this.pgId,
    this.pgName,
  });

  @override
  ConsumerState<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<ReportIssueDialog> {
  String _selectedReason = 'Food Quality or Safety';
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _reasons = [
    'Food Quality or Safety',
    'Incorrect Dietary / Allergen Label',
    'Portion Mismatch',
    'Pickup Window Closed Early',
    'Pricing / Payment Discrepancy',
    'Other Issue',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  'Report Listing or PG',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) => setState(() => _selectedReason = val ?? _reasons.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details / Description',
                hintText: 'Describe what happened so our moderation team can take action.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final user = ref.read(authProvider).currentUser;
                    ref.read(reportProvider.notifier).submitReport(
                          reporterId: user?.id ?? 'guest_cust',
                          reporterName: user?.fullName ?? 'Anonymous Customer',
                          listingId: widget.listingId,
                          listingTitle: widget.listingTitle,
                          pgId: widget.pgId,
                          pgName: widget.pgName,
                          reason: _selectedReason,
                          description: _descriptionController.text.trim(),
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted for admin review.')),
                    );
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
