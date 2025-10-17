import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class CustomTextfield extends StatelessWidget {
  final String label;
  final bool obsercure;
  final TextEditingController? controller; 

  const CustomTextfield({
    super.key,
    required this.label,
    this.obsercure = false,
    this.controller, 
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, 
      obscureText: obsercure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
      ),
    );
  }
}
