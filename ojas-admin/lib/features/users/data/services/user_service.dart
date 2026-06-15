import 'package:ojas_admin/core/services/api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _apiService.dio.get('/admin/users');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    try {
      await _apiService.dio.put('/admin/user-role/$id', data: {'role': role});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _apiService.dio.delete('/admin/user/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserStatus(String id, String status) async {
    try {
      await _apiService.dio.put('/admin/user-status/$id', data: {'status': status});
    } catch (e) {
      rethrow;
    }
  }
}
