import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/features/products/data/models/product_model.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  Future<List<ProductModel>> getAllProducts({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      final response = await _apiService.dio.get('/admin/product', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _apiService.dio.delete('/admin/product/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProductStatus(String id, String status) async {
    try {
      await _apiService.dio.put('/admin/product/$id', data: {'status': status});
    } catch (e) {
      rethrow;
    }
  }
}
