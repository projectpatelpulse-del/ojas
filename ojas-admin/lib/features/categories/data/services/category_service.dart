import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/core/services/service_locator.dart';

class CategoryService {
  final ApiService _apiService = sl<ApiService>();

  /// Safely extracts an error message from a Dio response body,
  /// handling both Map and plain-String response data.
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message']?.toString() ?? e.message ?? 'Unknown error';
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return e.message ?? 'Unknown error';
  }

  Future<List<dynamic>> getCategories({String? type}) async {
    try {
      log('Fetching categories with type: $type');
      final response = await _apiService.dio.get(
        '/admin/category',
        queryParameters: type != null ? {'type': type} : null,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] as List<dynamic>;
      }
      throw Exception('Failed to load categories');
    } on DioException catch (e) {
      log('DioError fetching categories: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('Error fetching categories: $e');
      throw Exception('Error fetching categories');
    }
  }

  Future<Map<String, dynamic>> updateCategoryStatus(String id, String status) async {
    try {
      log('Updating category status $id to $status');
      final response = await _apiService.dio.put(
        '/admin/category-status/$id',
        data: {'status': status},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      throw Exception('Failed to update category status');
    } on DioException catch (e) {
      log('DioError updating category status: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('Error updating category status: $e');
      throw Exception('Error updating category status');
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      log('Creating category: $categoryData');
      final response = await _apiService.dio.post(
        '/admin/category',
        data: categoryData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      throw Exception('Failed to create category');
    } on DioException catch (e) {
      log('DioError creating category: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('Error creating category: $e');
      throw Exception('Error creating category');
    }
  }

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      log('Updating category $id: $categoryData');
      final response = await _apiService.dio.put(
        '/admin/category/$id',
        data: categoryData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      throw Exception('Failed to update category');
    } on DioException catch (e) {
      log('DioError updating category: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('Error updating category: $e');
      throw Exception('Error updating category');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      log('Deleting category: $id');
      final response = await _apiService.dio.delete('/admin/category/$id');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete category');
      }
    } on DioException catch (e) {
      log('DioError deleting category: ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('Error deleting category: $e');
      throw Exception('Error deleting category');
    }
  }
}
