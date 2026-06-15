import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class OrderController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = false;

  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/order/all');
      if (response.statusCode == 200) {
        _orders = response.data['orders'] ?? [];
      }
    } catch (e) {
      debugPrint('Fetch all orders error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiService.dio.put('/order/status', data: {
        'orderId': orderId,
        'status': status,
      });
      if (response.statusCode == 200) {
        await fetchAllOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update order status error: $e');
      return false;
    }
  }

  Future<bool> assignDelhivery(String orderId, {Map<String, dynamic>? data}) async {
    try {
      final response = await _apiService.dio.post(
        '/order/assign-delivery/$orderId',
        data: data,
      );
      if (response.data['success']) {
        await fetchAllOrders();
        return true;
      }
      throw response.data['message'] ?? 'Failed to assign delivery';
    } catch (e) {
      debugPrint('Assign Delhivery error: $e');
      return false;
    }
  }
  Future<bool> updateOrderTracking(String orderId, Map<String, String> trackingInfo) async {
    try {
      final response = await _apiService.dio.put('/order/tracking', data: {
        'orderId': orderId,
        ...trackingInfo,
      });
      if (response.data['success']) {
        await fetchAllOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update order tracking error: $e');
      return false;
    }
  }
}
