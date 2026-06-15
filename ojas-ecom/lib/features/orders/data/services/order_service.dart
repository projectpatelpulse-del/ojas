import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';
import '../../domain/models/order_model.dart';

class OrderService {
  final String _endpoint = '${ApiService.baseUrl}/order';
  final AuthService _authService = AuthService();

  Future<List<OrderModel>> getUserOrders() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_endpoint/user'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List ordersJson = data['orders'] ?? [];
          return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    // Note: If backend doesn't have a specific get by ID, we can fetch all and filter
    // or we could add it to backend. For now, let's assume we can fetch all or search.
    try {
      final orders = await getUserOrders();
      return orders.firstWhere((o) => o.id == orderId || o.orderId == orderId);
    } catch (e) {
      return null;
    }
  }
}
