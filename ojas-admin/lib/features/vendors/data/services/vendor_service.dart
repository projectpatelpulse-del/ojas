import 'package:ojas_admin/core/services/api_service.dart';

class VendorService {
  final ApiService _apiService;

  VendorService(this._apiService);

  Future<List<dynamic>> getVendors() async {
    try {
      final response = await _apiService.dio.get('/admin/vendors');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getVendorRequests() async {
    try {
      final response = await _apiService.dio.get('/admin/vendor-requests');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVendorStatus(String id, String status) async {
    try {
      await _apiService.dio.put('/admin/vendor-status/$id', data: {'status': status});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVendor(String id) async {
    try {
      await _apiService.dio.delete('/admin/vendor/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVendorCommission(String id, double commissionRate) async {
    try {
      await _apiService.dio.put('/admin/vendor-commission/$id', data: {'commissionRate': commissionRate});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAllVendorsCommission(double commissionRate) async {
    try {
      await _apiService.dio.put('/admin/vendor-commission-all', data: {'commissionRate': commissionRate});
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorLedger(String userId) async {
    try {
      final response = await _apiService.dio.get('/admin/vendor-ledger/$userId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
