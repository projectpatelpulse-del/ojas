import 'package:dio/dio.dart';
import 'package:ojas_admin/core/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.dio.post('/admin/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to change password';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.dio.get('/admin/profile');
      return response.data['data'];
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to fetch profile';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
