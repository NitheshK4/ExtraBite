import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/demo/seed_data.dart';
import '../../models/pg_profile_model.dart';
import '../../services/audit_service.dart';
import '../../data/repositories/auth_repository.dart';

class OwnerApprovalsScreen extends StatefulWidget {
  const OwnerApprovalsScreen({super.key});

  @override
  State<OwnerApprovalsScreen> createState() => _OwnerApprovalsScreenState();
}

class _OwnerApprovalsScreenState extends State<OwnerApprovalsScreen> {
  late List<PgProfileModel> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = List.from(SeedData.pgProfiles);
  }

  void _approve(PgProfileModel pg, WidgetRef ref) {
    setState(() {
      final index = _profiles.indexWhere((p) => p.id == pg.id);
      if (index != -1) {
        _profiles[index] = _profiles[index].copyWith(isApproved: true);
      }
    });

    final admin = ref.read(authProvider).currentUser;
    if (admin != null) {
      ref.read(auditProvider.notifier).logEvent(
            actor: admin,
            action: 'PG_OWNER_APPROVED',
            entityType: 'pg_profile',
            entityId: pg.id,
            details: {'pg_name': pg.pgName, 'neighborhood': pg.neighborhood},
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${pg.pgName} has been approved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PG Owner Approvals'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final pg = _profiles[index];

          return Consumer(
            builder: (context, ref, _) {
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
                          Expanded(
                            child: Text(
                              pg.pgName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pg.isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pg.isApproved ? 'Approved' : 'Pending Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pg.isApproved ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Address: ${pg.address}, ${pg.neighborhood}'),
                      Text('Phone: ${pg.contactPhone}'),
                      if (pg.fssaiLicenseNumber != null)
                        Text('FSSAI License: ${pg.fssaiLicenseNumber}'),
                      const SizedBox(height: 12),
                      if (!pg.isApproved) ...[
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Rejected ${pg.pgName}')),
                                );
                              },
                              child: const Text('Reject', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                              onPressed: () => _approve(pg, ref),
                              child: const Text('Approve PG'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
