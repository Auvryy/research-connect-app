import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inquira/constants/colors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String? iconPath; // can be SVG or PNG

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.iconPath,
  });

  bool get _isSvg => iconPath != null && iconPath!.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.inputColor,
          side: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null) ...[
              _isSvg
                  ? SvgPicture.asset(iconPath!, height: 20, width: 20)
                  : Image.asset(iconPath!, height: 20, width: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
