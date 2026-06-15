import 'package:ojas_admin/core/services/api_service.dart';

class DashboardService {
  final ApiService _apiService;

  DashboardService(this._apiService);

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiService.dio.get('/admin/dashboard/stats');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return {};
    } catch (e) {
      print('Dashboard Service Error: $e');
      return {};
    }
  }
}
