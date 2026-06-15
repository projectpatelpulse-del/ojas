import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/features/banners/data/models/banner_model.dart';

class BannerService {
  final ApiService _apiService;

  BannerService(this._apiService);

  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _apiService.dio.get('/admin/banners');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => BannerModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createBanner({
    required String title,
    required String subtitle,
    required String link,
    required String tag,
    required String type,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'subtitle': subtitle,
        'link': link,
        'tag': tag,
        'type': type,
      });

      if (imageBytes != null) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(imageBytes, filename: fileName ?? 'banner.png'),
        ));
      }

      await _apiService.dio.post('/admin/banners', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBanner({
    required String id,
    String? title,
    String? subtitle,
    String? link,
    String? tag,
    String? type,
    bool? isActive,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (subtitle != null) data['subtitle'] = subtitle;
      if (link != null) data['link'] = link;
      if (tag != null) data['tag'] = tag;
      if (type != null) data['type'] = type;
      if (isActive != null) data['isActive'] = isActive.toString();

      FormData formData = FormData.fromMap(data);

      if (imageBytes != null) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(imageBytes, filename: fileName ?? 'banner.png'),
        ));
      }

      await _apiService.dio.put('/admin/banners/$id', data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _apiService.dio.delete('/admin/banners/$id');
    } catch (e) {
      rethrow;
    }
  }
}
