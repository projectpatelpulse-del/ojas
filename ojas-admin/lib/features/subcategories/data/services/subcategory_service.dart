import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/core/services/service_locator.dart';

class SubcategoryService {
  final ApiService _apiService = sl<ApiService>();

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message']?.toString() ?? e.message ?? 'Unknown error';
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return e.message ?? 'Unknown error';
  }

  Future<List<dynamic>> getSubcategories() async {
    try {
      final response = await _apiService.dio.get('/admin/subcategory');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      throw Exception('Failed to load subcategories');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Error fetching subcategories');
    }
  }

  Future<Map<String, dynamic>> createSubcategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/admin/subcategory', data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Failed to create subcategory');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Error creating subcategory');
    }
  }

  Future<Map<String, dynamic>> updateSubcategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/admin/subcategory/$id', data: data);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Failed to update subcategory');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Error updating subcategory');
    }
  }

  Future<void> deleteSubcategory(String id) async {
    try {
      await _apiService.dio.delete('/admin/subcategory/$id');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Error deleting subcategory');
    }
  }
}
