import 'dio_client.dart';

class OtpAPI {
  /// Send OTP to email for password reset
  /// Requires user to be logged in (JWT required)
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      print('OtpAPI.sendOtp: Sending OTP to $email');
      await DioClient.initOtp();

      final response = await DioClient.postOtp(
        '/send_otp',
        data: {
          'email': email,
        },
      );

      print('OtpAPI.sendOtp: Response received: $response');

      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return {
        'status': 500,
        'ok': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      print('OtpAPI.sendOtp: Error occurred: $e');
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Verify OTP code
  /// Requires user to be logged in (JWT required)
  static Future<Map<String, dynamic>> verifyOtp(String otp) async {
    try {
      print('OtpAPI.verifyOtp: Verifying OTP');
      await DioClient.initOtp();

      final response = await DioClient.postOtp(
        '/input_otp',
        data: {
          'otp': otp,
        },
      );

      print('OtpAPI.verifyOtp: Response received: $response');

      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return {
        'status': 500,
        'ok': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      print('OtpAPI.verifyOtp: Error occurred: $e');
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Reset password after OTP verification
  /// Requires user to be logged in (JWT required)
  static Future<Map<String, dynamic>> resetPassword(String newPassword) async {
    try {
      print('OtpAPI.resetPassword: Resetting password');
      await DioClient.initOtp();

      final response = await DioClient.patchOtp(
        '/reset_pssw',
        data: {
          'new_password': newPassword,
        },
      );

      print('OtpAPI.resetPassword: Response received: $response');

      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return {
        'status': 500,
        'ok': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      print('OtpAPI.resetPassword: Error occurred: $e');
      return {
        'status': 500,
        'ok': false,
        'message': e.toString(),
      };
    }
  }
}
