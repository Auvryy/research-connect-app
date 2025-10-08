import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor; 
  final VoidCallback? onEdit;

  const ProfileInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // --- Icon container ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // --- Label + Value ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),

          // --- Edit button (if provided) ---
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
