// import 'package:flutter/foundation.dart';

// class ApiService {
//   // Release builds: VPS Node (ojas_backend) — see ojas_backend PORT (default 5001).
//   static const String _prodUrl = 'https://api.ojasindia.com';
//   // 'http://72.61.172.182/api';
//   static const String _devUrl ='https://api.ojasindia.com/api';
//   //  'http://localhost:5001/api';

//   static String get baseUrl => kDebugMode ? _devUrl : _prodUrl;
//   // static String get serverUrl => baseUrl.replaceAll('/api', '');
//   static String get userBaseUrl => '$baseUrl/user';

//   static String formatImageUrl(String? url) {
//     if (url == null || url.isEmpty) {
//       return 'https://via.placeholder.com/500';
//     }
//     if (url.startsWith('http')) {
//       return url;
//     }
//     // Remove leading slash if exists
//     final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
//     return '$serverUrl/$cleanUrl';
//   }
// }




class ApiService {
  static const String _baseUrl =
  //  'http://localhost:5001/api';
   'https://api.ojasindia.com/api';

  static String get baseUrl => _baseUrl;

  static String get serverUrl => _baseUrl;

  static String get userBaseUrl => '$baseUrl/user';

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

    return '$serverUrl/$cleanUrl';
  }
}