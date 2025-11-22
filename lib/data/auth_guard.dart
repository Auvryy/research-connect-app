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
          
          // First, allow user in immediately (prevents redirect loop)
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
          
          // Then try to refresh token in background for security
          // Use timeout to prevent hanging on slow networks
          try {
            print('AuthGuard: Attempting to refresh token (background)...');
            final refreshResult = await AuthAPI.refreshToken().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('AuthGuard: Token refresh timed out (network slow), continuing with existing session');
                return {'ok': false, 'message': 'Timeout'};
              },
            );
            
            if (refreshResult['ok'] == true) {
              print('AuthGuard: Token refreshed successfully');
            } else {
              print('AuthGuard: Token refresh failed - ${refreshResult['message']}');
              // If token is actually expired (not just network issue), subsequent API calls will catch it
              // and redirect to login via DioClient interceptor
            }
          } catch (e) {
            print('AuthGuard: Exception during token refresh: $e');
            // Non-blocking - user continues with existing session
            // API calls will handle actual token expiration
          }
          
          return;
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
        print('AuthGuard: Redirecting to login...');
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // User is authenticated, show the requested page
    print('AuthGuard: User authenticated, showing page');
    return widget.child;
  }
}
