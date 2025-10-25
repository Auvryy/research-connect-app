import 'dio_client.dart';

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
      await DioClient.init();  // Ensure client is initialized
      final response = await DioClient.post(
        '/login',
        data: {
          "username": username,
          "password": password,
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;  // Pass through the detailed error message
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      await DioClient.init();  // Ensure client is initialized
      final response = await DioClient.post('/logout');
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;  // Pass through the detailed error message
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      await DioClient.init();  // Ensure client is initialized
      final response = await DioClient.post('/refresh');
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;  // Pass through the detailed error message
    }
  }
}
