import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';

class ResourceVendorService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getVendorResources() async {
    try {
      final response = await _apiService.dio.get('/resource/vendor');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['resources'] ?? [];
      }
    } catch (e) {
      debugPrint('Get Vendor Resources error: $e');
    }
    return [];
  }
}
