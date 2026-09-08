import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

import 'dart:async';
import '../../../core/utils/web_notification_helper.dart';

class OrderController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = false;
  Timer? _pollingTimer;
  Set<String> _knownOrderIds = {};

  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderController() {
    startAutoPolling();
  }

  void startAutoPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchVendorOrders(isSilent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> requestNotificationPermission() async {
    await WebNotificationHelper.requestPermission();
    notifyListeners();
  }

  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((o) {
    final s = o['status'].toString().toUpperCase();
    return s == 'PENDING' || s == 'CREATED';
  }).length;
  int get processingOrders => _orders.where((o) => o['status'].toString().toUpperCase() == 'PROCESSING').length;
  int get deliveredOrders => _orders.where((o) => o['status'].toString().toUpperCase() == 'DELIVERED').length;
  int get shippedOrders => _orders.where((o) {
    final s = o['status'].toString().toUpperCase();
    return s == 'SHIPPED' || s == 'SHIPMENT SCHEDULED';
  }).length;

  Future<void> fetchVendorOrders({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _apiService.dio.get('/order/vendor');
      if (response.statusCode == 200) {
        final List fetched = response.data['orders'] ?? [];

        // Detect new vendor orders for Web Notifications
        if (_knownOrderIds.isNotEmpty) {
          for (final order in fetched) {
            final String id = order['_id']?.toString() ?? '';
            if (id.isNotEmpty && !_knownOrderIds.contains(id)) {
              final String orderIdStr = order['orderId'] ?? 'New Order';
              WebNotificationHelper.showNotification(
                title: '📦 New Order for Store!',
                body: 'New order #$orderIdStr received (₹${order['totalAmount'] ?? 0})',
              );
            }
          }
        }

        _orders = fetched;
        _knownOrderIds = fetched.map((o) => o['_id']?.toString() ?? '').toSet();
      }
    } catch (e) {
      debugPrint('Fetch orders error: $e');
    } finally {
      if (!isSilent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiService.dio.put('/order/status', data: {
        'orderId': orderId,
        'status': status.toUpperCase(),
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
