import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

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
      fetchAllOrders(isSilent: true);
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

  Future<void> fetchAllOrders({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _apiService.dio.get('/order/all');
      if (response.statusCode == 200) {
        final List fetched = response.data['orders'] ?? [];
        
        // Detect new orders for Web Notifications
        if (_knownOrderIds.isNotEmpty) {
          for (final order in fetched) {
            final String id = order['_id']?.toString() ?? '';
            if (id.isNotEmpty && !_knownOrderIds.contains(id)) {
              final String orderIdStr = order['orderId'] ?? 'New Order';
              final String custName = order['user']?['name'] ?? 'Customer';
              WebNotificationHelper.showNotification(
                title: '🔔 New Order Received!',
                body: 'Order #$orderIdStr placed by $custName (₹${order['totalAmount'] ?? 0})',
              );
            }
          }
        }

        _orders = fetched;
        _knownOrderIds = fetched.map((o) => o['_id']?.toString() ?? '').toSet();
      }
    } catch (e) {
      debugPrint('Fetch all orders error: $e');
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
        await fetchAllOrders();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update order status error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> assignDelhivery(String orderId, {Map<String, dynamic>? data}) async {
    try {
      final response = await _apiService.dio.post(
        '/order/assign-delivery/$orderId',
        data: data,
      );
      if (response.data != null && response.data['success'] == true) {
        await fetchAllOrders();
        return {
          'success': true,
          'message': response.data['message'] ?? 'Shipment assigned successfully to Delhivery!'
        };
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to assign delivery'
      };
    } on DioException catch (e) {
      debugPrint('Assign Delhivery error: $e');
      final msg = e.response?.data != null && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : (e.message ?? 'Failed to assign delivery');
      return {'success': false, 'message': msg};
    } catch (e) {
      debugPrint('Assign Delhivery error: $e');
      return {'success': false, 'message': e.toString()};
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

  Future<String?> getDelhiveryLabelUrl(String orderId) async {
    try {
      final response = await _apiService.dio.get('/order/delhivery-label/$orderId');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['success'] == true) {
          return data['label']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get Delhivery Label error: $e');
      return null;
    }
  }
}
