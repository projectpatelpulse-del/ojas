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
      final String? varId = p is Map ? p['variationId']?.toString() : null;
      await addToWishlist(p, variationId: varId);
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
        _logWishlistState('WISHLIST LOADED FROM SERVER');
      }
    } catch (e) {
      debugPrint('[WishlistController] Error fetching wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _logWishlistState(String header) {
    debugPrint('\n==================== [$header: ${_wishlistItems.length} ITEMS] ====================');
    if (_wishlistItems.isEmpty) {
      debugPrint('Wishlist is empty.');
    } else {
      for (int i = 0; i < _wishlistItems.length; i++) {
        final it = _wishlistItems[i];
        final pName = it['name'] ?? 'Unknown Product';
        final pId = (it['productId'] ?? it['_id'] ?? it['id'])?.toString();
        final vId = it['variationId']?.toString() ?? 'None (Base Product)';
        final vTitle = it['variationTitle']?.toString() ?? 'None';
        final price = it['price'];
        final discPrice = it['discountPrice'];
        debugPrint('  #$i "$pName" (Product ID: $pId)');
        debugPrint('     -> Variation: "$vTitle" (Variation ID: $vId)');
        debugPrint('     -> Display Price: ₹$price (Discount: ₹$discPrice)');
      }
    }
    debugPrint('========================================================================\n');
  }

  bool isWishlisted(String? productId, {String? variationId}) {
    if (productId == null || productId.isEmpty) return false;
    return _wishlistItems.any((item) {
      final itemProdId = (item['productId'] ?? item['_id'] ?? item['id'] ?? '').toString();
      if (itemProdId != productId) return false;

      if (variationId != null && variationId.isNotEmpty) {
        final itemVarId = item['variationId']?.toString();
        return itemVarId == variationId;
      }
      return true;
    });
  }

  Future<void> toggleWishlist(dynamic product, {String? variationId, BuildContext? context}) async {
    final token = await AuthService().getToken();
    final bool isLoggedIn = SessionService.instance.isLoggedIn && token != null;

    final effectiveVarId = variationId ?? (product is Map ? product['variationId']?.toString() : null);
    final productId = (product is Map ? (product['productId'] ?? product['_id'] ?? product['id']) : product?.id)?.toString();

    debugPrint('[WishlistController] toggleWishlist requested -> Product ID: $productId, Variation ID: $effectiveVarId');

    if (!isLoggedIn) {
      setPendingProduct({
        if (product is Map) ...product else 'product': product,
        if (effectiveVarId != null) 'variationId': effectiveVarId,
      });
      if (context != null && context.mounted) {
        AppRouter.push(context, '/login');
      } else {
        AppRouter.router.push('/login');
      }
      return;
    }

    if (productId == null || productId.isEmpty) return;

    final isCurrentlyWishlisted = isWishlisted(productId, variationId: effectiveVarId);

    if (isCurrentlyWishlisted) {
      await removeFromWishlist(productId, variationId: effectiveVarId);
    } else {
      await addToWishlist(product, variationId: effectiveVarId);
    }
  }

  Future<void> addToWishlist(dynamic product, {String? variationId, BuildContext? context}) async {
    final token = await AuthService().getToken();
    final bool isLoggedIn = SessionService.instance.isLoggedIn && token != null;

    final effectiveVarId = variationId ?? (product is Map ? product['variationId']?.toString() : null);
    final productId = (product is Map ? (product['productId'] ?? product['_id'] ?? product['id']) : product?.id)?.toString();

    debugPrint('[WishlistController] addToWishlist -> Product ID: $productId, Variation ID: $effectiveVarId');

    if (!isLoggedIn) {
      setPendingProduct({
        if (product is Map) ...product else 'product': product,
        if (effectiveVarId != null) 'variationId': effectiveVarId,
      });
      if (context != null && context.mounted) {
        AppRouter.push(context, '/login');
      } else {
        AppRouter.router.push('/login');
      }
      return;
    }

    if (productId == null || productId.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/wishlist/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productId': productId,
          if (effectiveVarId != null && effectiveVarId.isNotEmpty) 'variationId': effectiveVarId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          _wishlistItems = data['data'];
          _logWishlistState('WISHLIST UPDATED AFTER ADD');
          notifyListeners();
        } else {
          await fetchWishlist();
        }
      }
    } catch (e) {
      debugPrint('[WishlistController] Error adding to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(String productId, {String? variationId}) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    debugPrint('[WishlistController] removeFromWishlist -> Product ID: $productId, Variation ID: $variationId');

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/wishlist/remove'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productId': productId,
          if (variationId != null && variationId.isNotEmpty) 'variationId': variationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          _wishlistItems = data['data'];
          _logWishlistState('WISHLIST UPDATED AFTER REMOVE');
          notifyListeners();
        } else {
          await fetchWishlist();
        }
      }
    } catch (e) {
      debugPrint('[WishlistController] Error removing from wishlist: $e');
    }
  }
}
