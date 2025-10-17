import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:5000', // backend URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static final cookieJar = CookieJar();

  DioClient() {
    // Add cookie manager interceptor (only once)
    if (!_dio.interceptors.any((e) => e is CookieManager)) {
      _dio.interceptors.add(CookieManager(cookieJar));
    }
  }

  // Generic POST request handler
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data; // backend returns JSON
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  // Generic GET handler (optional, for later use)
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }
}
