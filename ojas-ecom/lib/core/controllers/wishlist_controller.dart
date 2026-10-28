import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/routes/app_router.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';

class WishlistController with ChangeNotifier {
  static final WishlistController instance = WishlistController._internal();
  WishlistController._internal();

  List<dynamic> _wishlistItems = [];
  bool _isLoading = false;
  dynamic _pendingProduct;

  List<dynamic> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  int get count => _wishlistItems.length;
  dynamic get pendingProduct => _pendingProduct;

  void setPendingProduct(dynamic product) {
    _pendingProduct = product;
  }

  Future<void> processPendingWishlist() async {
    if (_pendingProduct != null) {
      final p = _pendingProduct;
      _pendingProduct = null;
      await addToWishlist(p);
    }
  }

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

  bool isWishlisted(String? productId) {
    if (productId == null || productId.isEmpty) return false;
    return _wishlistItems.any((item) => (item['_id'] ?? item['id'] ?? '').toString() == productId);
  }

  Future<void> toggleWishlist(dynamic product, {BuildContext? context}) async {
    final token = await AuthService().getToken();
    final bool isLoggedIn = SessionService.instance.isLoggedIn && token != null;

    if (!isLoggedIn) {
      setPendingProduct(product);
      if (context != null && context.mounted) {
        AppRouter.push(context, '/login');
      } else {
        AppRouter.router.push('/login');
      }
      return;
    }

    final productId = (product is Map ? (product['_id'] ?? product['id']) : product?.id)?.toString();
    if (productId == null || productId.isEmpty) return;

    final isCurrentlyWishlisted = isWishlisted(productId);

    if (isCurrentlyWishlisted) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(product);
    }
  }

  Future<void> addToWishlist(dynamic product, {BuildContext? context}) async {
    final token = await AuthService().getToken();
    final bool isLoggedIn = SessionService.instance.isLoggedIn && token != null;

    if (!isLoggedIn) {
      setPendingProduct(product);
      if (context != null && context.mounted) {
        AppRouter.push(context, '/login');
      } else {
        AppRouter.router.push('/login');
      }
      return;
    }

    final productId = (product is Map ? (product['_id'] ?? product['id']) : product?.id)?.toString();
    if (productId == null || productId.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/wishlist/add'),
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
