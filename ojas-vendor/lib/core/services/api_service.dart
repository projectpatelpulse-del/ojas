import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  static const String _prodUrl = 'https://api.ojasindia.com/api';
  static const String _devUrl = 'https://api.ojasindia.com/api';
  // static const String _devUrl = 'http://localhost:5001/api';
  static String get baseUrl => kDebugMode ? _devUrl : _prodUrl;

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('vendor_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          if (kDebugMode) {
            debugPrint('--- VENDOR API REQUEST ---');
            debugPrint('Method: ${options.method}');
            debugPrint('URL: ${options.baseUrl}${options.path}');
            debugPrint('Headers: ${options.headers}');
            debugPrint('Body: ${options.data}');
            debugPrint('--------------------------');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('--- VENDOR API RESPONSE ---');
            debugPrint('Status: ${response.statusCode}');
            debugPrint('Data: ${response.data}');
            debugPrint('---------------------------');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('--- VENDOR API ERROR ---');
            debugPrint('Status: ${e.response?.statusCode}');
            debugPrint('Error: ${e.response?.data ?? e.message} $e');
            debugPrint('------------------------');
          }
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('vendor_token');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
