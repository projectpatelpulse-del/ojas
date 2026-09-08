import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';

class FaqVendorService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getVendorFaqs() async {
    try {
      final response = await _apiService.dio.get('/faq/vendor');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['faqs'] ?? [];
      }
    } catch (e) {
      debugPrint('Get Vendor FAQs error: $e');
    }
    return [];
  }
}
