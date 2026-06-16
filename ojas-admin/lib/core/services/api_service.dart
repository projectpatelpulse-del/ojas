import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();

  // In debug mode hit the local backend (all routes are up to date).
  // In release/production build hit the live VPS.
  static const String _prodUrl = 'https://api.ojasindia.com/api';
  static const String _devUrl = 'http://localhost:5001/api';
  static String get baseUrl => kDebugMode ? _devUrl : _prodUrl;
//  static String get baseUrl => _prodUrl;
  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('admin_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('--- API REQUEST ---');
          debugPrint('Method: ${options.method}');
          debugPrint('URL: ${options.baseUrl}${options.path}');
          debugPrint('Headers: ${options.headers}');
          debugPrint('Body: ${options.data}');
          debugPrint('-------------------');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('--- API RESPONSE ---');
          debugPrint('Status: ${response.statusCode}');
          debugPrint('Data: ${response.data}');
          debugPrint('--------------------');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('--- API ERROR ---');
          debugPrint('Status: ${error.response?.statusCode}');
          debugPrint('Error: ${error.response?.data ?? error.message}');
          debugPrint('-----------------');
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/500';
    }

    if (url.startsWith('http')) {
      return url;
    }

    final cleanUrl = url.startsWith('/')
        ? url.substring(1)
        : url;

    return '$baseUrl/$cleanUrl';
  }
}
