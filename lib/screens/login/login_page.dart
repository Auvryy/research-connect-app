import 'package:flutter/material.dart';
import 'package:inquira/widgets/secondary_button.dart';
import 'package:inquira/widgets/toggle_login_register.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/primary_button.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/dio_client.dart'; // ✅ import our DioClient

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _loginUser() async {
    setState(() => _loading = true);

    try {
      final response = await DioClient().post(
        "/user/login",
        data: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      if (response["ok"] == true) {
        // success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // failed login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"].toString())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

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
              CustomTextfield(label: "Username", controller: _usernameController),
              const SizedBox(height: 20),
              CustomTextfield(label: "Password", obsercure: true, controller: _passwordController),
              const SizedBox(height: 15),
              PrimaryButton(
                text: _loading ? "Logging in..." : "Login",
                onPressed: _loading ? null : _loginUser,
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary)),
                  SizedBox(width: 10),
                  Text(
                    "or",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Divider(thickness: 2.0, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                text: "Sign in with Google",
                iconPath: 'assets/images/google-icon.png',
                onPressed: () {
                  print('Google clicked');
                },
              ),
              const SizedBox(height: 5),
              ToggleLoginRegister(
                normalText: "Don't have an account?",
                linkText: "Register",
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/register');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
