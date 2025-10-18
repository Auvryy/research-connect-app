import 'dio_client.dart';

class AuthAPI {
  // ✅ Register endpoint
  static Future<dynamic> register(String email, String password) async {
    try {
      final response = await DioClient().post(
        '/user/register',
        data: {
          "email": email,
          "password": password,
        },
      );
      return response;
    } catch (e) {
      throw Exception("Register failed: $e");
    }
  }

  // ✅ Login endpoint
  static Future<dynamic> login(String email, String password) async {
    try {
      final response = await DioClient().post(
        '/user/login',
        data: {
          "email": email,
          "password": password,
        },
      );
      return response;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // ✅ Logout endpoint
  static Future<dynamic> logout() async {
    try {
      final response = await DioClient().post('/user/logout');
      return response;
    } catch (e) {
      throw Exception("Logout failed: $e");
    }
  }

  // ✅ Refresh token endpoint
  static Future<dynamic> refreshToken() async {
    try {
      final response = await DioClient().post('/user/refresh');
      return response;
    } catch (e) {
      throw Exception("Refresh token failed: $e");
    }
  }
}
