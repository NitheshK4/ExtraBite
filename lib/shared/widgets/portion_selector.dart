import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PortionSelector extends StatelessWidget {
  final int count;
  final int maxCount;
  final ValueChanged<int> onChanged;

  const PortionSelector({
    super.key,
    required this.count,
    required this.maxCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: count > 1 ? () => onChanged(count - 1) : null,
            color: AppColors.primary,
            disabledColor: Colors.grey.shade400,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: count < maxCount ? () => onChanged(count + 1) : null,
            color: AppColors.primary,
            disabledColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
