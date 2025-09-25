import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class ToggleLoginRegister extends StatelessWidget{
  final String normalText;
  final String linkText;
  final VoidCallback onTap;

  const ToggleLoginRegister({
    super.key,
    required this.normalText,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: normalText),
          const TextSpan(text: " "),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: AppColors.accent1,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),

    );
  }
}