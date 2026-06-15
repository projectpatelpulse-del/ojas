import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';

class VendorSettingsService {
  final ApiService _apiService = sl<ApiService>();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiService.dio.get('/vendor/settings');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/vendor/settings', data: data);
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.dio.put('/vendor/settings/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
}
