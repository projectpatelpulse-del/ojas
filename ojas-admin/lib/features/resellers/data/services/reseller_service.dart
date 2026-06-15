import 'package:ojas_admin/core/services/api_service.dart';

class ResellerService {
  final ApiService _apiService;

  ResellerService(this._apiService);

  Future<List<dynamic>> getResellers() async {
    try {
      final response = await _apiService.dio.get('/admin/resellers');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveReseller(String resellerId) async {
    try {
      await _apiService.dio.put('/admin/reseller/approve', data: {'resellerId': resellerId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> blockReseller(String resellerId) async {
    try {
      await _apiService.dio.put('/admin/reseller/block', data: {'resellerId': resellerId});
    } catch (e) {
      rethrow;
    }
  }
}
