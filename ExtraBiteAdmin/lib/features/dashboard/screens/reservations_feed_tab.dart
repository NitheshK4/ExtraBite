import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/admin_reservation.dart';
import '../../../providers/admin_provider.dart';

class ReservationsFeedTab extends ConsumerStatefulWidget {
  const ReservationsFeedTab({super.key});

  @override
  ConsumerState<ReservationsFeedTab> createState() => _ReservationsFeedTabState();
}

class _ReservationsFeedTabState extends ConsumerState<ReservationsFeedTab> {
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadReservations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReservationDetailModal(AdminReservation res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Reservation ${res.readableId}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              _buildDetailRow('Reference ID', res.readableId, isMonospace: true),
              _buildDetailRow('Surplus Food Meal', res.foodTitle),
              _buildDetailRow('PG Mess Facility', res.pgName),
              _buildDetailRow('Customer Name', res.customerName),
              _buildDetailRow('Customer Email', res.customerEmail.isNotEmpty ? res.customerEmail : '—'),
              _buildDetailRow('Portions Reserved', '${res.portionsCount} Portion(s)'),
              _buildDetailRow('Unit Price', '₹${res.unitPrice.toStringAsFixed(0)}'),
              _buildDetailRow(
                'Total Billable Amount',
                '₹${res.totalAmount.toStringAsFixed(0)} (${res.paymentMethod.replaceAll('_', ' ').toUpperCase()})',
              ),
              _buildDetailRow(
                'Pickup Deadline',
                DateFormat('MMMM dd, yyyy - hh:mm a').format(res.pickupDeadline),
              ),
              _buildDetailRow(
                'Created Timestamp',
                DateFormat('MMMM dd, yyyy - hh:mm a').format(res.createdAt),
              ),
              if (res.pickedUpAt != null)
                _buildDetailRow(
                  'Completed At',
                  DateFormat('MMMM dd, yyyy - hh:mm a').format(res.pickedUpAt!),
                ),
              if (res.cancellationReason != null)
                _buildDetailRow('Cancellation Reason', res.cancellationReason!),
              _buildDetailRow(
                'Lifecycle Status',
                res.status.replaceAll('_', ' ').toUpperCase(),
                statusColor: res.status == 'picked_up' || res.status == 'completed'
                    ? AppColors.primary
                    : (res.status == 'cancelled' ? AppColors.error : AppColors.secondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false, Color? statusColor}) {
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
                      color: statusColor ?? AppColors.onSurface,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor ?? AppColors.onSurface,
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
    final allReservations = adminState.reservations;

    // Filter
    final filteredReservations = allReservations.where((r) {
      if (_selectedStatusFilter == 'CONFIRMED' && r.status != 'confirmed') return false;
      if (_selectedStatusFilter == 'READY' && r.status != 'ready_for_pickup') return false;
      if (_selectedStatusFilter == 'COMPLETED' && r.status != 'picked_up' && r.status != 'completed') return false;
      if (_selectedStatusFilter == 'CANCELLED' && r.status != 'cancelled') return false;

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.toLowerCase().trim();
        final ref = r.readableId.toLowerCase();
        final food = r.foodTitle.toLowerCase();
        final cust = r.customerName.toLowerCase();
        final email = r.customerEmail.toLowerCase();
        final pg = r.pgName.toLowerCase();
        return ref.contains(q) || food.contains(q) || cust.contains(q) || email.contains(q) || pg.contains(q);
      }
      return true;
    }).toList();

    final totalCount = allReservations.length;
    final confirmedCount = allReservations.where((r) => r.status == 'confirmed').length;
    final completedCount = allReservations.where((r) => r.status == 'picked_up' || r.status == 'completed').length;
    final cancelledCount = allReservations.where((r) => r.status == 'cancelled').length;

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
                          'Reservations Live Feed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live monitor of student reservations, pickup verification, and completion audits.',
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
                    onPressed: () => ref.read(adminProvider.notifier).loadReservations(),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh Reservations',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  _buildStatPill('Total Orders', '$totalCount', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildStatPill('Confirmed', '$confirmedCount', AppColors.secondary),
                  const SizedBox(width: 12),
                  _buildStatPill('Completed', '$completedCount', AppColors.success),
                  const SizedBox(width: 12),
                  _buildStatPill('Cancelled', '$cancelledCount', AppColors.error),
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
                          hintText: 'Search by reference ID (#EB-XXXX), food item, student, or PG...',
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
                        _buildFilterButton('ALL', 'All Reservations'),
                        _buildFilterButton('CONFIRMED', 'Confirmed'),
                        _buildFilterButton('READY', 'Ready for Pickup'),
                        _buildFilterButton('COMPLETED', 'Completed'),
                        _buildFilterButton('CANCELLED', 'Cancelled'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Reservations Table
              if (adminState.isLoading && allReservations.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filteredReservations.isEmpty)
                _buildEmptyState()
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
                          DataColumn(label: Text('REFERENCE ID')),
                          DataColumn(label: Text('MEAL & PG FACILITY')),
                          DataColumn(label: Text('STUDENT CUSTOMER')),
                          DataColumn(label: Text('QTY')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('PICKUP DEADLINE')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filteredReservations.map((res) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    res.readableId,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      res.foodTitle,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      res.pgName,
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
                                      res.customerName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      res.customerEmail.isNotEmpty ? res.customerEmail : '—',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${res.portionsCount}x',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '₹${res.totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormat('MMM dd, hh:mm a').format(res.pickupDeadline),
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              DataCell(_buildStatusBadge(res.status)),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                  tooltip: 'View Order Details',
                                  onPressed: () => _showReservationDetailModal(res),
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
      'picked_up' || 'completed' => AppColors.primary,
      'confirmed' || 'ready_for_pickup' => AppColors.secondary,
      'cancelled' || 'rejected' => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No reservations found matching current filter.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
