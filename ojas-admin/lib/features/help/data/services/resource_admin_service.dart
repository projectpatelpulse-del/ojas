import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

class ResourceAdminService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getAllResources() async {
    try {
      final response = await _apiService.dio.get('/resource/admin');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['resources'] ?? [];
      }
    } catch (e) {
      debugPrint('Get all Resources error: $e');
    }
    return [];
  }

  Future<bool> createResource(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/resource', data: data);
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Create Resource error: $e');
      return false;
    }
  }

  Future<bool> updateResource(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/resource/$id', data: data);
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Update Resource error: $e');
      return false;
    }
  }

  Future<bool> deleteResource(String id) async {
    try {
      final response = await _apiService.dio.delete('/resource/$id');
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Delete Resource error: $e');
    }
    return false;
  }

  Future<String?> uploadPdf(Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'pdf': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _apiService.dio.post('/upload/pdf', data: formData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'];
      }
    } catch (e) {
      debugPrint('Upload PDF error: $e');
    }
    return null;
  }
}
