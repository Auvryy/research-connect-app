import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/widgets/custom_textfield.dart';
import '/widgets/primary_button.dart';
import 'package:inquira/widgets/secondary_button.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/toggle_login_register.dart';
import 'package:inquira/data/api/auth_api.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _agreedToTerms = false;
  bool _loading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool get _isFormValid {
    return _usernameError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _agreedToTerms;
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateUsername);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  void _validateUsername() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _usernameError = "Username is required";
    } else if (username.length < 4) {
      _usernameError = "Username must be at least 4 characters";
    } else if (username.length > 36) {
      _usernameError = "Username must not exceed 36 characters";
    } else {
      _usernameError = null;
    }
    setState(() {});
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      _passwordError = "Password is required";
    } else {
      List<String> requirements = [];
      
      if (password.length < 8) requirements.add("at least 8 characters");
      if (password.length > 36) requirements.add("no more than 36 characters");
      if (!password.contains(RegExp(r'[A-Z]'))) requirements.add("one uppercase letter");
      if (!password.contains(RegExp(r'[a-z]'))) requirements.add("one lowercase letter");
      if (!password.contains(RegExp(r'[0-9]'))) requirements.add("one number");
      if (!password.contains(RegExp(r'[!@#$%^&*()_\-+=<>?/]'))) requirements.add("one special character (e.g., @, #, _, -)");
      
      if (requirements.isNotEmpty) {
        _passwordError = "Password must include: ${requirements.join(", ")}";
      } else {
        _passwordError = null;
      }
    }
    _validateConfirmPassword();
    setState(() {});
  }

  void _validateConfirmPassword() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = "Please confirm your password";
    } else if (password != confirmPassword) {
      _confirmPasswordError = "Passwords do not match";
    } else {
      _confirmPasswordError = null;
    }
    setState(() {});
  }

  Future<void> _registerUser() async {
    if (!_isFormValid) return;

    setState(() => _loading = true);
    try {
      final response = await AuthAPI.register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {  // Check if widget is still mounted
        if (response["ok"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!")),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          final message = response["message"];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message is String ? message : "Registration failed"
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {  // Check if widget is still mounted
        String errorMessage;
        if (e is Map) {
          errorMessage = (e["message"] as String?) ?? "Registration failed";
        } else {
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {  // Check if widget is still mounted
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = _isFormValid && !_loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
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
                "Create and share surveys, or discover insights by answering others — only on Inquira.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
              const SizedBox(height: 30),

              // Username
              CustomTextfield(
                label: "Username",
                controller: _usernameController,
              ),
              if (_usernameError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _usernameError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Password
              CustomTextfield(
                label: "Password",
                obsercure: true,
                controller: _passwordController,
              ),
              if (_passwordError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Confirm Password
              CustomTextfield(
                label: "Confirm Password",
                obsercure: true,
                controller: _confirmPasswordController,
              ),
              if (_confirmPasswordError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _confirmPasswordError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms & Services",
                            style:
                                const TextStyle(color: AppColors.accent1),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style:
                                const TextStyle(color: AppColors.accent1),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Button
              PrimaryButton(
                text: _loading ? "Creating..." : "Create Account",
                onPressed: isButtonEnabled ? _registerUser : null,
              ),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Expanded(
                      child:
                          Divider(thickness: 2.0, color: AppColors.primary)),
                  SizedBox(width: 10),
                  Text(
                    "or",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                      child:
                          Divider(thickness: 2.0, color: AppColors.primary)),
                ],
              ),

              const SizedBox(height: 10),

              SecondaryButton(
                text: "Continue with Google",
                iconPath: "assets/images/google-icon.png",
                onPressed: () {},
              ),

              const SizedBox(height: 10),

              ToggleLoginRegister(
                normalText: "Have an account?",
                linkText: "Login",
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
