import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

class OrderController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = false;

  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;

  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((o) => o['status'] == 'Pending').length;
  int get processingOrders => _orders.where((o) => o['status'] == 'Processing').length;
  int get deliveredOrders => _orders.where((o) => o['status'] == 'Delivered').length;
  int get shippedOrders => _orders.where((o) => o['status'] == 'Shipped').length;

  Future<void> fetchVendorOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/order/vendor');
      if (response.statusCode == 200) {
        _orders = response.data['orders'] ?? [];
      }
    } catch (e) {
      debugPrint('Fetch orders error: $e');
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
        await fetchVendorOrders();
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
        await fetchVendorOrders();
        return true;
      }
      throw response.data['message'] ?? 'Failed to assign delivery';
    } catch (e) {
      debugPrint('Assign Delhivery error: $e');
      if (e is DioException) {
        throw e.response?.data['message'] ?? 'Network Error: ${e.message}';
      }
      rethrow;
    }
  }

  Future<bool> confirmDelivery(String orderId) async {
    try {
      final response = await _apiService.dio.put('/order/confirm-delivery', data: {
        'orderId': orderId,
      });
      if (response.statusCode == 200) {
        await fetchVendorOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Confirm delivery error: $e');
      return false;
    }
  }

  Future<bool> submitPickupDetails(String orderId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/order/pickup-details', data: {
        'orderId': orderId,
        ...data,
      });
      if (response.statusCode == 200) {
        await fetchVendorOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Submit pickup details error: $e');
      return false;
    }
  }

  Future<bool> submitPickedUpPhoto(String orderId, String photoUrl) async {
    try {
      final response = await _apiService.dio.put('/order/picked-up-photo', data: {
        'orderId': orderId,
        'pickedUpPhoto': photoUrl,
      });
      if (response.statusCode == 200) {
        await fetchVendorOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Submit picked up photo error: $e');
      return false;
    }
  }

  Future<bool> submitDispatchPhoto(String orderId, String photoUrl) async {
    try {
      final response = await _apiService.dio.put('/order/dispatch-photo', data: {
        'orderId': orderId,
        'dispatchPhoto': photoUrl,
      });
      if (response.statusCode == 200) {
        await fetchVendorOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Submit dispatch photo error: $e');
      return false;
    }
  }
}
