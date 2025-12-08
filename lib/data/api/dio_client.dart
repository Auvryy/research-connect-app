import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class DioClient {
  static Dio? _dio;
  static Dio? _dioOtp;
  static CookieJar? _cookieJar;
  static bool _initializing = false;
  static bool _initializingOtp = false;

  static Future<Dio> get instance async {
    if (_dio == null) {
      if (!_initializing) {
        await init();
      }
    }
    return _dio!;
  }

  // Helper: fetch a cookie value by name from the base host
  static Future<String?> _getCookieValue(String name) async {
    if (_cookieJar == null) return null;
    final uri = Uri.parse('http://10.0.2.2:5000');
    final cookies = await _cookieJar!.loadForRequest(uri);
    for (final cookie in cookies) {
      if (cookie.name == name) return cookie.value;
    }
    return null;
  }

  // Helper: choose correct CSRF token (access vs refresh)
  static Future<String?> _getCsrfToken({bool useRefreshToken = false}) async {
    final name = useRefreshToken ? 'csrf_refresh_token' : 'csrf_access_token';
    return _getCookieValue(name);
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

      // Attach CSRF token header from cookies on every request
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Decide which CSRF token to use
            final isRefreshRequest = options.path.contains('/refresh');
            final csrfToken = await _getCsrfToken(useRefreshToken: isRefreshRequest);
            if (csrfToken != null) {
              options.headers['X-CSRF-TOKEN'] = csrfToken;
            }
          } catch (e) {
            // If we fail to inject CSRF, continue without blocking the request
            print('DioClient: CSRF inject failed: $e');
          }
          return handler.next(options);
        },
      ));

      // Add interceptor for automatic token refresh
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Before each request, try to refresh token proactively if needed
          // This prevents the "Access token expired" error from showing to users
          return handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Check if error message indicates token expiration
          final errorMsg = error.response?.data?['message']?.toString().toLowerCase() ?? '';
          final isTokenExpired = error.response?.statusCode == 401 || 
                                errorMsg.contains('access token expired') ||
                                errorMsg.contains('token has expired') ||
                                errorMsg.contains('please log in');
          
          // Don't retry refresh endpoint itself
          final isRefreshRequest = error.requestOptions.path.contains('/refresh');
          
          if (isTokenExpired && !isRefreshRequest) {
            print('DioClient: Token expired, attempting refresh...');
            try {
              // Create a new dio instance without interceptors to avoid infinite loop
              final refreshDio = Dio(BaseOptions(
                baseUrl: 'http://10.0.2.2:5000/api/user',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ));
              if (_cookieJar != null) {
                refreshDio.interceptors.add(CookieManager(_cookieJar!));
              }
              
              final refreshResponse = await refreshDio.post('/refresh');
              
              if (refreshResponse.statusCode == 200 && refreshResponse.data['ok'] == true) {
                print('DioClient: Token refreshed successfully, retrying request...');
                
                // Retry the original request with refreshed token
                final options = error.requestOptions;
                final retryDio = Dio(BaseOptions(
                  baseUrl: dio.options.baseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ));
                if (_cookieJar != null) {
                  retryDio.interceptors.add(CookieManager(_cookieJar!));
                }
                
                final response = await retryDio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                );
                return handler.resolve(response);
              } else {
                print('DioClient: Token refresh returned non-success');
              }
            } catch (e) {
              print('DioClient: Token refresh failed: $e');
              // If refresh fails, user needs to login again
            }
          }
          return handler.next(error);
        },
      ));

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

  static Future<void> initOtp() async {
    if (_dioOtp != null || _initializingOtp) return;
    _initializingOtp = true;

    try {
      // Ensure base client is initialized for cookie sharing
      await init();

      final dioOtp = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:5000/api/otp',
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

      // Share cookie jar with main client
      if (_cookieJar != null) {
        dioOtp.interceptors.add(CookieManager(_cookieJar!));
      }

      // Inject CSRF token for OTP endpoints as well
      dioOtp.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final csrfToken = await _getCsrfToken();
            if (csrfToken != null) {
              options.headers['X-CSRF-TOKEN'] = csrfToken;
            }
          } catch (e) {
            print('DioClient OTP: CSRF inject failed: $e');
          }
          return handler.next(options);
        },
      ));

      // Add logging interceptor
      dioOtp.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));

      _dioOtp = dioOtp;
    } catch (e) {
      print('Error initializing DioClient OTP: $e');
      rethrow;
    } finally {
      _initializingOtp = false;
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

  static Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async {
    final dio = await instance;
    try {
      print('Making PATCH request to: ${dio.options.baseUrl}$path');
      print('Request data: $data');
      
      final response = await dio.patch(
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

  static Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    final dio = await instance;
    try {
      print('Making PUT request to: ${dio.options.baseUrl}$path');
      print('Request data: $data');
      
      final response = await dio.put(
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
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  static Future<dynamic> delete(String path) async {
    final dio = await instance;
    try {
      print('Making DELETE request to: ${dio.options.baseUrl}$path');
      
      final response = await dio.delete(
        path,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  static Future<dynamic> uploadFile(
    String path,
    dynamic file,
    {String fieldName = 'file', String method = 'POST'}
  ) async {
    final dio = await instance;
    try {
      print('Making file upload request ($method) to: ${dio.options.baseUrl}$path');
      
      String fileName = 'upload';
      if (file is File) {
        fileName = file.path.split('/').last;
      }
      
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file is File ? file.path : file.toString(),
          filename: fileName,
        ),
      });
      
      final response = await dio.request(
        path,
        data: formData,
        options: Options(
          method: method,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  // OTP-specific methods
  static Future<dynamic> postOtp(String path, {Map<String, dynamic>? data}) async {
    if (_dioOtp == null) await initOtp();
    try {
      print('Making POST request to OTP endpoint: ${_dioOtp!.options.baseUrl}$path');
      print('Request data: $data');
      
      final response = await _dioOtp!.post(
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
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  static Future<dynamic> patchOtp(String path, {Map<String, dynamic>? data}) async {
    if (_dioOtp == null) await initOtp();
    try {
      print('Making PATCH request to OTP endpoint: ${_dioOtp!.options.baseUrl}$path');
      print('Request data: $data');
      
      final response = await _dioOtp!.patch(
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
      print('Response data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('DioError Type: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response}');
      
      if (e.response?.data is Map) {
        throw e.response?.data['message'] ?? 'An error occurred';
      } else if (e.response?.data is String) {
        throw e.response?.data ?? 'An error occurred';
      } else {
        throw e.message ?? 'An error occurred';
      }
    }
  }

  /// Clear all cookies (used during logout)
  static Future<void> clearCookies() async {
    try {
      if (_cookieJar != null) {
        await _cookieJar!.deleteAll();
        print('DioClient: Cookies cleared');
      }
    } catch (e) {
      print('DioClient: Error clearing cookies: $e');
    }
  }
}
