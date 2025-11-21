import 'package:flutter/material.dart';
import 'package:inquira/widgets/secondary_button.dart';
import 'package:inquira/widgets/toggle_login_register.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/primary_button.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/user_info.dart';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

final dio = Dio();
final cookieJar = CookieJar();

void setupDio() {
  dio.interceptors.add(CookieManager(cookieJar));
}

Future<void> loginWithOAuth() async {
  final url = "https://carlie-vile-workably.ngrok-free.dev/api/oauth/login?redirect_url=flutter";

  // 1. Start OAuth login
  final result = await FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: "myapp",
  );

  // result will look like: myapp://oauth-callback?code=XYZ
  final msg = Uri.parse(result).queryParameters["msg"];
  final loginType = Uri.parse(result).queryParameters["login_type"];

  print(msg);
  print(loginType);

  // // 2. Exchange code for token
  // final response = await dio.post(
  //   "http://localhost:5000/api/oauth/exchange",
  //   data: {"code": code},
  // );

  // print("TOKEN: ${response.data}");
}


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
    if (_usernameController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both username and password")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await AuthAPI.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response["ok"] == true) {
        // Load user info and set currentUser
        final userInfo = await UserInfo.loadUserInfo();
        if (userInfo != null) {
          currentUser = userInfo;
          print('Login successful. Current user: ${currentUser?.username}');
        }
        
        // success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login successful!")),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // failed login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["message"] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
              const SizedBox(height: 10),
              CustomTextField(label: "Username", controller: _usernameController),
              const SizedBox(height: 10),
              CustomTextField(label: "Password", obscureText: true, controller: _passwordController),
              const SizedBox(height: 10),
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
                onPressed: () async {
                  try {
                    await loginWithOAuth();
                  } catch (e) {
                    print("error loggin in with google $e");
                  }
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
