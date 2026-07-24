import 'package:ojas_vendor/core/services/api_service.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService(this._apiService);

  Future<List<dynamic>> getCategories({bool tree = false}) async {
    try {
      final response = await _apiService.dio.get(
        '/vendor/category',
        queryParameters: tree ? {'tree': 'true'} : null,
      );
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPublicCategories() async {
    try {
      final response = await _apiService.dio.get(
        '/home/categories',
        queryParameters: {'type': 'approved'},
      );
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
