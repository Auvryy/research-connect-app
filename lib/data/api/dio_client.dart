import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class DioClient {
  static Dio? _dio;
  static CookieJar? _cookieJar;
  static bool _initializing = false;

  static Future<Dio> get instance async {
    if (_dio == null) {
      if (!_initializing) {
        await init();
      }
    }
    return _dio!;
  }

  static Future<void> init() async {
    if (_dio != null || _initializing) return;
    _initializing = true;

    try {
      // Get valid storage directory for your cookies
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = '${appDocDir.path}/.cookies/';
      
      // Create cookie directory if it doesn't exist
      Directory(cookiePath).createSync(recursive: true);

      // Initialize cookie jar with persistent storage
      _cookieJar = PersistCookieJar(
        storage: FileStorage(cookiePath),
        ignoreExpires: true,
      );

      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:5000/api/user',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
          followRedirects: true,
          receiveDataWhenStatusError: true,
        ),
      );

      // Add cookie manager
      if (_cookieJar != null) {
        dio.interceptors.add(CookieManager(_cookieJar!));
      }

      // Add logging interceptor for debugging
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));

      _dio = dio;
    } catch (e) {
      print('Error initializing DioClient: $e');
      rethrow;
    } finally {
      _initializing = false;
    }
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    final dio = await instance;
    try {
      print('Making POST request to: ${dio.options.baseUrl}$path');
      print('Request data: $data');
      
      final response = await dio.post(
        path,
        data: data,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      print('Response Data: ${e.response?.data}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final dio = await instance;
    try {
      print('Making GET request to: ${dio.options.baseUrl}$path');
      print('Query parameters: $params');
      
      final response = await dio.get(
        path,
        queryParameters: params,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      print('Response Data: ${e.response?.data}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }
}
