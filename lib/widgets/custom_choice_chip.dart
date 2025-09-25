import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inquira/constants/colors.dart';

class CustomChoiceChip extends StatelessWidget{
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final String? svgAsset;

  const CustomChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.svgAsset,

  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgAsset != null) ...[
            SvgPicture.asset(
              svgAsset!,
              width: 20,
              height: 20,
              color: selected ? AppColors.background : AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      shadowColor: Colors.black26,
      elevation: 2,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.primary,
        width: 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}