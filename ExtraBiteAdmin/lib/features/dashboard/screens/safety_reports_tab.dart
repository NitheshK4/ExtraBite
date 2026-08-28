import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/admin_report.dart';
import '../../../providers/admin_provider.dart';

class SafetyReportsTab extends ConsumerStatefulWidget {
  const SafetyReportsTab({super.key});

  @override
  ConsumerState<SafetyReportsTab> createState() => _SafetyReportsTabState();
}

class _SafetyReportsTabState extends ConsumerState<SafetyReportsTab> {
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showResolveReportModal(AdminReport report) {
    final notesController = TextEditingController(text: report.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Review Safety Incident',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                _buildDetailRow('Report ID', report.id, isMonospace: true),
                _buildDetailRow('Violation Reason', report.reason),
                if (report.listingTitle != null)
                  _buildDetailRow('Flagged Meal', report.listingTitle!),
                if (report.pgName != null)
                  _buildDetailRow('Flagged PG Facility', report.pgName!),
                _buildDetailRow('Reporter', '${report.reporterName} (${report.reporterEmail})'),
                if (report.description != null && report.description!.isNotEmpty)
                  _buildDetailRow('Incident Details', report.description!),
                _buildDetailRow(
                  'Submitted Date',
                  DateFormat('MMMM dd, yyyy - hh:mm a').format(report.createdAt),
                ),
                const SizedBox(height: 16),
                Text(
                  'ADMIN RESOLUTION NOTES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter internal notes and resolution rationale...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).resolveReport(
                    report.id,
                    'dismissed',
                    notesController.text.trim(),
                  );
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
            child: const Text('Dismiss Report'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).resolveReport(
                    report.id,
                    'resolved',
                    notesController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final allReports = adminState.reports;

    // Filter
    final filteredReports = allReports.where((r) {
      if (_selectedStatusFilter == 'PENDING' && r.status != 'pending') return false;
      if (_selectedStatusFilter == 'RESOLVED' && r.status != 'resolved') return false;
      if (_selectedStatusFilter == 'DISMISSED' && r.status != 'dismissed') return false;

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.toLowerCase().trim();
        final reason = r.reason.toLowerCase();
        final rep = r.reporterName.toLowerCase();
        final email = r.reporterEmail.toLowerCase();
        final listing = (r.listingTitle ?? '').toLowerCase();
        final pg = (r.pgName ?? '').toLowerCase();
        return reason.contains(q) || rep.contains(q) || email.contains(q) || listing.contains(q) || pg.contains(q);
      }
      return true;
    }).toList();

    final totalCount = allReports.length;
    final pendingCount = allReports.where((r) => r.status == 'pending').length;
    final resolvedCount = allReports.where((r) => r.status == 'resolved').length;
    final dismissedCount = allReports.where((r) => r.status == 'dismissed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & KPI Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety & Incident Reports',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Food safety escalations, quality complaints, and incident investigation queue.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => ref.read(adminProvider.notifier).loadReports(),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh Reports',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  _buildStatPill('Total Reports', '$totalCount', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildStatPill('Pending Investigation', '$pendingCount', AppColors.error),
                  const SizedBox(width: 12),
                  _buildStatPill('Resolved', '$resolvedCount', AppColors.success),
                  const SizedBox(width: 12),
                  _buildStatPill('Dismissed', '$dismissedCount', AppColors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Filter & Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by reason, reporter, meal, or PG property...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterButton('ALL', 'All Reports'),
                        _buildFilterButton('PENDING', 'Pending'),
                        _buildFilterButton('RESOLVED', 'Resolved'),
                        _buildFilterButton('DISMISSED', 'Dismissed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Reports Table or Empty State
              if (adminState.isLoading && allReports.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filteredReports.isEmpty)
                _buildCleanSafetyState()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.surfaceContainerHigh),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('INCIDENT / REASON')),
                          DataColumn(label: Text('FLAGGED ENTITY')),
                          DataColumn(label: Text('REPORTER')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('REPORTED DATE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filteredReports.map((report) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      report.reason,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      report.id.substring(0, report.id.length >= 8 ? 8 : report.id.length),
                                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      report.listingTitle ?? report.pgName ?? 'Platform Listing',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      report.pgName ?? 'PG Mess',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      report.reporterName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      report.reporterEmail,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(_buildStatusBadge(report.status)),
                              DataCell(
                                Text(
                                  DateFormat('MMM dd, yyyy').format(report.createdAt),
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  onPressed: () => _showResolveReportModal(report),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryContainer,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.manage_search, size: 16),
                                  label: const Text('Review Incident'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status.toLowerCase()) {
      'pending' => AppColors.error,
      'resolved' => AppColors.success,
      'dismissed' => AppColors.onSurfaceVariant,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCleanSafetyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Zero Active Safety Incidents',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Platform food safety standards and PG partner compliance are currently in good standing.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
