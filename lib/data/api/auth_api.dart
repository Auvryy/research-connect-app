import 'dio_client.dart';
import '../user_info.dart';

class AuthAPI {
  /// Validates registration input against backend requirements
  static Map<String, String?> validateRegistration(String username, String password) {
    Map<String, String?> errors = {};
    
    // Username validation
    if (username.isEmpty) {
      errors['username'] = 'Missing username';
    } else if (username.length < 4) {
      errors['username'] = 'Username must be at least 4 characters';
    } else if (username.length > 36) {
      errors['username'] = 'Username must not exceed 36 characters';
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Missing password';
    } else {
      if (password.length < 8) {
        errors['password'] = 'Password must be at least 8 characters';
      } else if (password.length > 36) {
        errors['password'] = 'Password must not exceed 36 characters';
      } else if (!password.contains(RegExp(r'[A-Z]'))) {
        errors['password'] = 'Password must contain at least 1 uppercase letter';
      } else if (!password.contains(RegExp(r'[a-z]'))) {
        errors['password'] = 'Password must contain at least 1 lowercase letter';
      } else if (!password.contains(RegExp(r'[0-9]'))) {
        errors['password'] = 'Password must contain at least 1 digit';
      } else if (!password.contains(RegExp(r'[!@#$%^&*()_\-+=<>?/]'))) {
        errors['password'] = 'Password must contain at least 1 special character (e.g., @, #, _, -)';
      }
    }
    
    return errors;
  }

  static Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      // Validate input before making the request
      final validationErrors = validateRegistration(username, password);
      if (validationErrors.isNotEmpty) {
        return {
          'status': 400,
          'ok': false,
          'message': validationErrors.values.first,
        };
      }

      print('Initializing DioClient for registration...');
      await DioClient.init();  // Ensure client is initialized
      
      print('Sending registration request for username: $username');
      final response = await DioClient.post(
        '/register',  // Matches backend endpoint
        data: {
          "username": username,
          "password": password,
        },
      );

      print('Registration response received: $response');
      if (response is Map<String, dynamic>) {
        // The backend always returns a response with status, ok, and message fields
        final status = response['status'] as int?;
        final isSuccess = response['ok'] as bool?;
        final message = response['message'];
        
        // Create a properly formatted response
        final formattedResponse = {
          'status': status ?? 500,
          'ok': isSuccess ?? false,
          'message': message is Map ? 
              // Handle validation errors which come as a map
              (message['username'] ?? message['password'] ?? 'Validation error') :
              // Handle string messages
              (message?.toString() ?? 'Unknown error'),
        };
        
        return formattedResponse;
      } else {
        return {
          'status': 500,
          'ok': false,
          'message': 'Invalid server response format',
        };
      }
    } catch (e) {
      // Log the error for debugging
      print('Registration error: $e');
      
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('AuthAPI.login: Starting login for username: $username');
      await DioClient.init();  // Ensure client is initialized
      
      final response = await DioClient.post(
        '/login',
        data: {
          "username": username,
          "password": password,
        },
      );
      
      print('AuthAPI.login: Response received: $response');
      
      // Handle different response types
      if (response is Map<String, dynamic>) {
        final status = response['status'] as int?;
        final isSuccess = response['ok'] as bool?;
        final message = response['message'];
        
        // If login is successful, fetch user data and save it
        if (isSuccess == true && status == 200) {
          print('AuthAPI.login: Login successful, fetching user data...');
          
          // Call the /login_success endpoint to get user details
          try {
            final userDataResponse = await DioClient.get('/login_success');
            print('AuthAPI.login: User data response: $userDataResponse');
            
            if (userDataResponse is Map<String, dynamic> && 
                userDataResponse['ok'] == true) {
              final userData = userDataResponse['message'];
              
              if (userData is Map<String, dynamic>) {
                // Get profile pic and ensure it's null if empty
                String? profilePicUrl = userData['profile_pic'] as String?;
                if (profilePicUrl != null && profilePicUrl.trim().isEmpty) {
                  profilePicUrl = null;
                }
                
                // Create UserInfo from the response
                final userInfo = UserInfo(
                  id: userData['id'] as int?,
                  username: userData['username'] as String,
                  profilePicUrl: profilePicUrl,
                );
                
                // Save user info to SharedPreferences
                await UserInfo.saveUserInfo(userInfo);
                print('AuthAPI.login: User info saved successfully');
              }
            }
          } catch (userDataError) {
            print('AuthAPI.login: Error fetching user data: $userDataError');
            // Continue even if fetching user data fails
          }
        }
        
        return {
          'status': status ?? 500,
          'ok': isSuccess ?? false,
          'message': message?.toString() ?? 'Unknown error',
        };
      } else if (response is String) {
        return {
          'status': 500,
          'ok': false,
          'message': response,
        };
      } else {
        return {
          'status': 500,
          'ok': false,
          'message': 'Invalid response format',
        };
      }
    } catch (e) {
      print('AuthAPI.login: Exception occurred: $e');
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      print('AuthAPI.logout: Starting logout...');
      await DioClient.init();  // Ensure client is initialized
      
      final response = await DioClient.post('/refresh/logout');
      print('AuthAPI.logout: Response received: $response');
      
      // Clear user data regardless of response
      await UserInfo.clearUserInfo();
      print('AuthAPI.logout: User info cleared from SharedPreferences');
      
      // Clear cookies
      await DioClient.clearCookies();
      print('AuthAPI.logout: Cookies cleared');
      
      // Handle different response types
      if (response is Map<String, dynamic>) {
        return response;
      } else if (response is String) {
        return {
          'status': 200,
          'ok': true,
          'message': response,
        };
      } else {
        return {
          'status': 200,
          'ok': true,
          'message': 'Logged out successfully',
        };
      }
    } catch (e) {
      print('AuthAPI.logout: Error occurred: $e');
      
      // Clear user data even if the API call fails
      await UserInfo.clearUserInfo();
      await DioClient.clearCookies();
      
      // Return success anyway since local data is cleared
      return {
        'status': 200,
        'ok': true,
        'message': 'Logged out locally',
      };
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      print('AuthAPI.refreshToken: Attempting to refresh token...');
      await DioClient.init();  // Ensure client is initialized
      
      final response = await DioClient.post('/refresh');
      
      print('AuthAPI.refreshToken: Response received - $response');
      
      // Handle different response types
      if (response is Map<String, dynamic>) {
        if (response['ok'] == true) {
          print('AuthAPI.refreshToken: Token refreshed successfully');
          return {'ok': true, 'message': 'Token refreshed'};
        } else {
          print('AuthAPI.refreshToken: Server returned error: ${response['message']}');
          return response;
        }
      } else if (response is String) {
        print('AuthAPI.refreshToken: String response: $response');
        return {
          'ok': false,
          'message': response,
        };
      } else {
        print('AuthAPI.refreshToken: Invalid response format');
        return {
          'ok': false,
          'message': 'Invalid response format',
        };
      }
    } catch (e) {
      print('AuthAPI.refreshToken: Error - $e');
      return {
        'ok': false,
        'message': 'Token refresh failed: $e',
      };
    }
  }



  /// Upload user avatar/profile picture using backend's /profile_upload endpoint
  static Future<Map<String, dynamic>> uploadAvatar(dynamic imageFile) async {
    try {
      print('AuthAPI.uploadAvatar: Starting avatar upload...');
      await DioClient.init();

      // Backend expects PATCH request to /profile_upload with 'profile_pic' field
      final response = await DioClient.uploadFile(
        '/profile_upload',
        imageFile,
        fieldName: 'profile_pic',
        method: 'PATCH',
      );
      
      print('AuthAPI.uploadAvatar: Response received: $response');

      if (response is Map<String, dynamic>) {
        // If upload is successful, reload user data to get updated profile pic
        if (response['ok'] == true) {
          // Fetch updated user data from /login_success
          try {
            final userDataResponse = await DioClient.get('/login_success');
            if (userDataResponse is Map<String, dynamic> && userDataResponse['ok'] == true) {
              final userData = userDataResponse['message'];
              if (userData is Map<String, dynamic>) {
                // Get profile pic and ensure it's null if empty
                String? profilePicUrl = userData['profile_pic'] as String?;
                if (profilePicUrl != null && profilePicUrl.trim().isEmpty) {
                  profilePicUrl = null;
                }
                
                final userInfo = UserInfo(
                  id: userData['id'] as int?,
                  username: userData['username'] as String,
                  profilePicUrl: profilePicUrl,
                );
                await UserInfo.saveUserInfo(userInfo);
                currentUser = userInfo;
                print('AuthAPI.uploadAvatar: Profile pic URL updated locally');
              }
            }
          } catch (e) {
            print('AuthAPI.uploadAvatar: Error reloading user data: $e');
          }
        }

        return response;
      } else {
        return {
          'status': 500,
          'ok': false,
          'message': 'Invalid response format',
        };
      }
    } catch (e) {
      print('AuthAPI.uploadAvatar: Error occurred: $e');
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }




}
