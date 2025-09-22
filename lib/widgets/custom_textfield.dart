import 'package:flutter/material.dart';

class CustomTextfield extends StatelessWidget{
  final String label;
  final bool obsercure;

  const CustomTextfield({super.key, required this.label, this. obsercure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obsercure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF151515), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF151515), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF151515), width: 2.5),

        ),
      ),
    );
  }
}