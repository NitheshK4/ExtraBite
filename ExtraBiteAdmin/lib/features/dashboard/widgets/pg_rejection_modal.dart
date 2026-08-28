import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class PgRejectionModal extends StatefulWidget {
  final String pgName;

  const PgRejectionModal({
    super.key,
    required this.pgName,
  });

  static Future<String?> show(BuildContext context, String pgName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PgRejectionModal(pgName: pgName),
    );
  }

  @override
  State<PgRejectionModal> createState() => _PgRejectionModalState();
}

class _PgRejectionModalState extends State<PgRejectionModal> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  final List<String> _categories = [
    'Inaccurate Address or Geolocation Coordinates',
    'Unreachable Contact / Invalid Phone Number',
    'Invalid or Expired FSSAI License',
    'Kitchen Hygiene & Food Safety Concern',
    'Incomplete Documentation / Missing Photos',
    'Other Policy Non-Compliance',
  ];

  late String _selectedCategory;
  bool _notifyOwner = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[0];
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final feedback = _feedbackController.text.trim();
      final fullReason = feedback.isNotEmpty
          ? '[$_selectedCategory] $feedback'
          : _selectedCategory;
      Navigator.of(context).pop(fullReason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reject Property Application',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Action for: ${widget.pgName}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(null),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'The property registration will be placed in rejected status. The PG owner will receive feedback on necessary corrections before they can re-submit.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Rejection Category Selector
                Text(
                  'Rejection Category *',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: AppColors.surface,
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Admin Feedback Note TextField
                Text(
                  'Admin Feedback Note *',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter specific reason and instructions for the owner (e.g. FSSAI registration certificate is expired, or coordinate pinpoint is outside premises)...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant.withOpacity(0.7)),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.error, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide feedback notes explaining the rejection.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Notification Checkbox
                InkWell(
                  onTap: () {
                    setState(() {
                      _notifyOwner = !_notifyOwner;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _notifyOwner,
                          activeColor: AppColors.error,
                          onChanged: (val) {
                            setState(() {
                              _notifyOwner = val ?? true;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Send notification email to PG Owner (where email service is active)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(
                        'Confirm Rejection',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
