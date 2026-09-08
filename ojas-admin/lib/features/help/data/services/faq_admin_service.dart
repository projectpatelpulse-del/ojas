import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';

class FaqAdminService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getAllFaqs() async {
    try {
      final response = await _apiService.dio.get('/faq/admin');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['faqs'] ?? [];
      }
    } catch (e) {
      debugPrint('Get all FAQs error: $e');
    }
    return [];
  }

  Future<bool> createFaq(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/faq', data: data);
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Create FAQ error: $e');
      return false;
    }
  }

  Future<bool> updateFaq(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/faq/$id', data: data);
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Update FAQ error: $e');
      return false;
    }
  }

  Future<bool> deleteFaq(String id) async {
    try {
      final response = await _apiService.dio.delete('/faq/$id');
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Delete FAQ error: $e');
      return false;
    }
  }
}
