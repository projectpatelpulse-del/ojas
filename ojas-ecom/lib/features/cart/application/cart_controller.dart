import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_service.dart';
import 'package:ojas_user/core/services/session_service.dart';


class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  static CartController get instance => _instance;

  CartController._internal() {
    _initCart();
  }

  Future<void> _initCart() async {
    await _loadLocalCart();
    final token = await _getToken();
    if (token != null) {
      await loadCart();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_auth_token');
  }

  Future<void> _loadLocalCart() async {
    final token = await _getToken();
    if (token == null) {
      _items = [];
      notifyListeners();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString('local_cart_data');
      if (savedCart != null) {
        _items = json.decode(savedCart);
        notifyListeners();
      }
    } catch (e) {
      _items = [];
    }
  }

  Future<void> _saveLocalCart(List<dynamic> items) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_cart_data', json.encode(items));
    } catch (e) {
      debugPrint('Failed to save local cart: $e');
    }
  }

  final CartService _cartService = CartService();
  List<dynamic> _items = [];
  bool _isLoading = false;
  
  // Pending cart item logic
  String? _pendingProductId;
  int? _pendingMoq;

  void setPendingItem(String productId, int? moq) {
    _pendingProductId = productId;
    _pendingMoq = moq;
  }

  Future<void> processPendingCart() async {
    if (_pendingProductId != null) {
      final String id = _pendingProductId!;
      final int? moq = _pendingMoq;
      _pendingProductId = null;
      _pendingMoq = null;
      await addToCart(id, moq: moq);
    }
  }

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;

  double get subtotal {
    double total = 0;
    for (var item in _items) {
      final product = item['product'];
      if (product != null && product is Map) {
        double price = (product['discountPrice'] != null && product['discountPrice'] > 0 
            ? product['discountPrice'] 
            : (product['price'] ?? 0)).toDouble();
            
        int quantity = item['quantity'] ?? 1;
        int moq = product['moq'] ?? 1;
        double moqDiscount = (product['moqDiscount'] ?? 0).toDouble();

        if (quantity >= moq && moqDiscount > 0) {
          price = price - (price * (moqDiscount / 100));
        }
        
        // Use ceiling to match display rounding on all product cards
        price = price.ceilToDouble();
            
        total += price * quantity;
      }
    }
    return total;
  }

  double get savings {
    double saved = 0;
    for (var item in _items) {
      final product = item['product'];
      if (product != null && product is Map && product['price'] != null) {
        double originalPrice = (product['price']).toDouble();
        double currentPrice = (product['discountPrice'] != null && product['discountPrice'] > 0 
            ? product['discountPrice'] 
            : originalPrice).toDouble();

        int quantity = item['quantity'] ?? 1;
        int moq = product['moq'] ?? 1;
        double moqDiscount = (product['moqDiscount'] ?? 0).toDouble();

        if (quantity >= moq && moqDiscount > 0) {
          currentPrice = currentPrice - (currentPrice * (moqDiscount / 100));
        }
        
        // Use ceiling to match display rounding on all product cards
        currentPrice = currentPrice.ceilToDouble();

        double diff = originalPrice - currentPrice;
        if (diff > 0) {
          saved += diff * quantity;
        }
      }
    }
    return saved;
  }

  /// Dynamic tax: sum of (sellingPrice × qty × gstPercent/100) per item.
  /// Uses gstPercent field set by the backend (processCartItems), falling back to
  /// the product's gst field, then to 0 if neither is available.
  double get tax {
    double totalTax = 0;
    for (var item in _items) {
      final product = item['product'];
      if (product != null && product is Map) {
        double price = (product['discountPrice'] != null && product['discountPrice'] > 0
            ? product['discountPrice']
            : (product['price'] ?? 0)).toDouble();

        int quantity = item['quantity'] ?? 1;
        int moq = product['moq'] ?? 1;
        double moqDiscount = (product['moqDiscount'] ?? 0).toDouble();
        if (quantity >= moq && moqDiscount > 0) {
          price = price - (price * (moqDiscount / 100));
        }
        price = price.ceilToDouble();

        // Prefer backend-calculated gstPercent on the item itself, then the
        // product's gst field (backend always sends at least one of these).
        final double gstRate = ((item['gstPercent'] ?? product['gstPercent'] ?? product['gst'] ?? 0) as num).toDouble();
        totalTax += price * quantity * gstRate / 100;
      }
    }
    return totalTax;
  }

  double get totalAmount => subtotal + tax;

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiItems = await _cartService.getCart();
      // Only override if we received a valid list response (even if empty, it means true empty)
      _items = apiItems;
      _saveLocalCart(_items);
    } catch(e) {
      // Fallback to local items if API utterly fails or is completely unauthorized
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(String productId, {int quantity = 1, int? moq}) async {
    final token = await _getToken();
    if (token == null) return false;
    
    int qtyToAdd = quantity;
    if (moq != null && moq > 1 && quantity == 1) {
      bool exists = _items.any((item) {
        final p = item['product'];
        return p != null && (p['_id'] == productId || p['id'] == productId);
      });
      if (!exists) {
        qtyToAdd = moq;
      }
    }

    final refCode = (SessionService.instance.referredProductId == productId)
        ? SessionService.instance.refCode
        : null;

    final success = await _cartService.addToCart(productId, quantity: qtyToAdd, referralCode: refCode);
    if (success) {
      await loadCart();
      return true;
    }
    return false;
  }

  Future<bool> removeFromCart(String productId) async {
    final token = await _getToken();
    if (token == null) return false;

    final success = await _cartService.removeFromCart(productId);
    if (success) {
      await loadCart();
      return true;
    }
    return false;
  }

  void clear() {
    _items = [];
    _saveLocalCart([]);
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await _cartService.checkout(
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
    );
    
    if (response['success'] == true) {
      if (paymentMethod == "COD") {
        _items = []; // Optimistically clear cart for COD
        _saveLocalCart(_items);
        await loadCart();
      }
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }
}
