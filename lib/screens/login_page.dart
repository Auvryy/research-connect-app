import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart  ';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              const Text(
                "Inquira",
                style: TextStyle(
                  fontSize: 32, 
                  fontFamily: 'Giaza',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Create and share surveys, or discover insights by answering others—only on Inquira.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 40),

              //username input
              const CustomTextfield(label: "Username"),
              const SizedBox(height: 20),

              //password input
              const CustomTextfield(label: "Password", obsercure: true),
              const SizedBox(height: 30),

              //login button
              PrimaryButton(
                text: "Login",
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),

            ]
          ),
        ),
      ),

    );
  }
}