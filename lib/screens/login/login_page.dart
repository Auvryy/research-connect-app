import 'package:flutter/material.dart';
import 'package:inquira/widgets/secondary_button.dart';
import 'package:inquira/widgets/toggle_login_register.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/primary_button.dart';
import 'package:inquira/constants/colors.dart';


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
                  fontSize: 36, 
                  fontFamily: 'Giaza',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Create and share surveys, or discover insights by answering others—only on Inquira.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 30),

              //username input
              const CustomTextfield(label: "Username"),
              const SizedBox(height: 20),

              //password input
              const CustomTextfield(label: "Password", obsercure: true),
              const SizedBox(height: 15),

              //login button
              PrimaryButton(
                text: "Login",
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/register');
                },
              ),

              SizedBox(height: 10),

              Row(
                children: const[
                  
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary),),
                  SizedBox(width: 10,),
                  Text(
                    "or",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10,),
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary))
                ],
              ),

              SizedBox(height: 10),

              SecondaryButton(
                text: "Sign in with google",
                iconPath: 'assets/images/google-icon.png',
                onPressed: () {
                  print('Google clicked');
                },

              ),

              SizedBox(height: 5),

              ToggleLoginRegister(
                normalText: "Don't have an account?", 
                linkText: "Register", 
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/register');
                }
              )

            ]
          ),
        ),
      ),

    );
  }
}