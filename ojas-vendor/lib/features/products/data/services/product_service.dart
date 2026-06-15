import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:ojas_vendor/core/services/api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  Future<Response> createProduct(Map<String, dynamic> productData, {XFile? mainImage, List<XFile>? gallery}) async {
    try {
      FormData formData = FormData.fromMap(productData);

      if (mainImage != null) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(await mainImage.readAsBytes(), filename: 'product_image.png'),
        ));
      }

      if (gallery != null && gallery.isNotEmpty) {
        for (var file in gallery) {
          formData.files.add(MapEntry(
            'gallery',
            MultipartFile.fromBytes(await file.readAsBytes(), filename: 'gallery_${DateTime.now().millisecondsSinceEpoch}.png'),
          ));
        }
      }

      return await _apiService.dio.post('/vendor/product', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateProduct(String id, Map<String, dynamic> productData, {XFile? mainImage, List<XFile>? gallery}) async {
    try {
      FormData formData = FormData.fromMap(productData);

      if (mainImage != null) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(await mainImage.readAsBytes(), filename: 'product_image.png'),
        ));
      }

      if (gallery != null && gallery.isNotEmpty) {
        for (var file in gallery) {
          formData.files.add(MapEntry(
            'gallery',
            MultipartFile.fromBytes(await file.readAsBytes(), filename: 'gallery_${DateTime.now().millisecondsSinceEpoch}.png'),
          ));
        }
      }

      return await _apiService.dio.put('/vendor/product/$id', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteProduct(String id) async {
    try {
      return await _apiService.dio.delete('/vendor/product/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _apiService.dio.get('/vendor/products');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }
}
