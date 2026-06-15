import '../../../../core/services/api_service.dart';
import '../../domain/models/admin_model.dart';

class AdminManagementService {
  final ApiService _apiService;

  AdminManagementService(this._apiService);

  Future<List<AdminModel>> getAllAdmins() async {
    try {
      final response = await _apiService.dio.get('/admin/get-all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => AdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateAdminStatus(String id, String status) async {
    try {
      final response = await _apiService.dio.put(
        '/admin/admin-status/$id',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAdmin(String id) async {
    try {
      final response = await _apiService.dio.delete('/admin/admin/$id');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateAdminPermissions(String id, List<String> permissions) async {
    try {
      final response = await _apiService.dio.put(
        '/admin/admin-permissions/$id',
        data: {'permissions': permissions},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
