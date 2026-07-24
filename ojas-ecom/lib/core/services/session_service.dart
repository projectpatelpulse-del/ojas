import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';
import 'package:ojas_user/features/cart/application/cart_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  static SessionService get instance => _instance;

  SessionService._internal();

  final ValueNotifier<UserModel?> userNotifier = ValueNotifier<UserModel?>(null);
  final ValueNotifier<bool> isInitializedNotifier = ValueNotifier<bool>(false);
  String? _token;
  String? _refCode;
  String? _referredProductId;

  UserModel? get currentUser => userNotifier.value;
  bool get isLoggedIn => userNotifier.value != null;
  bool get isInitialized => isInitializedNotifier.value;
  String? get token => _token;
  String? get refCode => _refCode;
  String? get referredProductId => _referredProductId;

  Future<void> setReferral(String? ref, String? productId) async {
    _refCode = ref;
    _referredProductId = productId;
    // Commented out SharedPreferences persistence to keep referral at session-level only.
    // When browser/tab is closed, memory resets and referral clears automatically.
    // final prefs = await SharedPreferences.getInstance();
    // if (ref != null && productId != null) {
    //   await prefs.setString('referral_code', ref);
    //   await prefs.setString('referred_product_id', productId);
    // } else {
    //   await prefs.remove('referral_code');
    //   await prefs.remove('referred_product_id');
    // }
    notifyListeners();
  }

  Future<void> loadReferral() async {
    // Commented out loading referral from SharedPreferences to keep it in-memory session only.
    // final prefs = await SharedPreferences.getInstance();
    // _refCode = prefs.getString('referral_code');
    // _referredProductId = prefs.getString('referred_product_id');
    notifyListeners();
  }

  void setUser(UserModel? user, {String? token}) {
    userNotifier.value = user;
    if (token != null) _token = token;
    if (user == null) {
      _token = null;
      CartController.instance.clear();
      WishlistController.instance.fetchWishlist(); // Will clear since token is null
    } else {
      WishlistController.instance.fetchWishlist();
    }
    notifyListeners();
  }

  Future<void> initSession() async {
    try {
      await loadReferral();
      final authService = AuthService();
      _token = await authService.getToken();
      final user = await authService.getCurrentUser();
      userNotifier.value = user;
      
      if (user != null) {
        await CartController.instance.loadCart();
        await WishlistController.instance.fetchWishlist();
      }
    } catch (e) {
      userNotifier.value = null;
      _token = null;
    } finally {
      isInitializedNotifier.value = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final authService = AuthService();
    await authService.logout();
    CartController.instance.clear();
    WishlistController.instance.fetchWishlist();
    userNotifier.value = null;
    _token = null;
    notifyListeners();
  }
}
