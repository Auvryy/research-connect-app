import 'package:flutter/material.dart';
import 'user_info.dart';
import 'api/auth_api.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await UserInfo.isLoggedIn();
      
      if (isLoggedIn) {
        // Load user info
        final userInfo = await UserInfo.loadUserInfo();
        if (userInfo != null) {
          currentUser = userInfo;
          print('AuthGuard: User session found - ${userInfo.username}');
          
          // Try to refresh token to verify session is still valid
          try {
            final refreshResponse = await AuthAPI.refreshToken();
            if (refreshResponse['ok'] == true) {
              print('AuthGuard: Session refreshed successfully');
              setState(() {
                _isAuthenticated = true;
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            print('AuthGuard: Token refresh failed: $e');
          }
        }
      }
      
      // If we get here, user is not authenticated or session is invalid
      print('AuthGuard: No valid session found');
      currentUser = null;
      await UserInfo.clearUserInfo();
      
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    } catch (e) {
      print('AuthGuard: Error checking authentication: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
