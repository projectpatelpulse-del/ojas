import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';

class WishlistController with ChangeNotifier {
  static final WishlistController instance = WishlistController._internal();
  WishlistController._internal();

  List<dynamic> _wishlistItems = [];
  bool _isLoading = false;

  List<dynamic> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  int get count => _wishlistItems.length;

  Future<void> init() async {
    await fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    final token = await AuthService().getToken();
    if (token == null) {
      _wishlistItems = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user/wishlist'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _wishlistItems = data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isWishlisted(String productId) {
    return _wishlistItems.any((item) => item['_id'] == productId);
  }

  Future<void> toggleWishlist(dynamic product) async {
    final productId = product['_id'];
    final isCurrentlyWishlisted = isWishlisted(productId);

    if (isCurrentlyWishlisted) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(product);
    }
  }

  Future<void> addToWishlist(dynamic product) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/wishlist/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productId': product['_id']}),
      );

      if (response.statusCode == 200) {
        // Optimistic update or refresh
        await fetchWishlist();
      }
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/wishlist/remove'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        // Optimistic update or refresh
        await fetchWishlist();
      }
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
    }
  }
}
