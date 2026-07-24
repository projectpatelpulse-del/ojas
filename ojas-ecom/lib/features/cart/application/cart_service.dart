import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ojas_user/core/services/api_service.dart';

class CartService {
  final Dio _dio = Dio();

  CartService() {
    _dio.options.baseUrl = ApiService.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<bool> addToCart(String productId, {int quantity = 1, String? referralCode, String? variationId}) async {
    try {
      final Map<String, dynamic> body = {
        'productId': productId,
        'quantity': quantity,
      };
      if (referralCode != null) {
        body['referralCode'] = referralCode;
      }
      if (variationId != null) {
        body['variationId'] = variationId;
      }
      final response = await _dio.post(
        '/user/cart/add',
        data: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getCart() async {
    try {
      final response = await _dio.get('/user/cart');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> removeFromCart(String productId, {String? variationId}) async {
    try {
      final Map<String, dynamic> body = {'productId': productId};
      if (variationId != null) {
        body['variationId'] = variationId;
      }
      final response = await _dio.post(
        '/user/cart/remove',
        data: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkout({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        '/order/create',
        data: {
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        },
      );
      if (response.statusCode == 201) {
        return response.data;
      }
      return {'success': false, 'message': 'Failed to create order'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
