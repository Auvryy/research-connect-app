import 'package:flutter/material.dart';
import 'screens/login/create_account_page.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inquira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF151515),
        fontFamily: 'Poppins',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const CreateAccountPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
