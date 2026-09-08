import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/socket_service.dart';

import 'package:ojas_user/features/home/data/models/banner_model.dart';

class HomeController with ChangeNotifier {
  static final HomeController instance = HomeController._internal();
  HomeController._internal();

  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  List<BannerModel> _banners = [];
  bool _isLoading = false;

  List<dynamic> get categories => _categories;

  /// All products (Active status is handled by backend)
  List<dynamic> get products => _products;
  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;

  List<dynamic> get homeProducts =>
      _products.where((p) => _containsPage(p, 'Home')).toList();
  List<dynamic> get featureProducts =>
      _products.where((p) => _containsPage(p, 'Features')).toList();
  List<dynamic> get dealProducts =>
      _products.where((p) => _containsPage(p, 'Deals')).toList();
  List<dynamic> get shopProducts =>
      _products.where((p) => _containsPage(p, 'Shop')).toList();
  List<dynamic> get trendingProducts =>
      _products.where((p) => _containsPage(p, 'Trending')).toList();
  List<dynamic> get dailyDealsProducts =>
      _products.where((p) => _containsPage(p, 'Daily Deals') || _containsPage(p, 'Deals')).toList();
  List<dynamic> get justForYouProducts =>
      _products.where((p) => _containsPage(p, 'Just For You')).toList();
  List<dynamic> get latestProducts =>
      _products.where((p) => _containsPage(p, 'Latest Products')).toList();


  bool _containsPage(dynamic p, String page) {
    final pages = p['showOnPages'];
    if (pages == null) return page == 'Shop'; // Default to Shop if null
    if (pages is List) {
      return pages.any(
        (item) => item.toString().toLowerCase() == page.toLowerCase(),
      );
    }
    return false;
  }

  List<BannerModel> get mainBanners => _banners
      .where(
        (b) =>
            b.type == 'main' ||
            b.type == 'main_slider',
      )
      .toList();
  BannerModel get sideTopBanner => _banners.firstWhere(
    (b) => b.type == 'side_top',
    orElse: () => _defaultSideTop,
  );
  BannerModel get sideBottomBanner => _banners.firstWhere(
    (b) => b.type == 'side_bottom',
    orElse: () => _defaultSideBottom,
  );
  BannerModel get offerBanner => _banners.firstWhere(
    (b) => b.type == 'offer',
    orElse: () => _defaultOfferBanner,
  );
  BannerModel get trendingBanner => _banners.firstWhere(
    (b) => b.type == 'trending',
    orElse: () => _defaultTrendingBanner,
  );
  BannerModel get summerSaleBanner => _banners.firstWhere(
    (b) => b.type == 'summer_sale',
    orElse: () => _defaultSummerSaleBanner,
  );
  BannerModel get becomeVendorBanner => _banners.firstWhere(
    (b) => b.type == 'become_vendor',
    orElse: () => _defaultBecomeVendorBanner,
  );
  BannerModel get vendorAuthBanner => _banners.firstWhere(
    (b) => b.type == 'vendor_auth',
    orElse: () => _defaultVendorAuthBanner,
  );
  BannerModel get resellerAuthBanner => _banners.firstWhere(
    (b) => b.type == 'reseller_auth',
    orElse: () => _defaultResellerAuthBanner,
  );
  BannerModel get promoGrid0 => _banners.firstWhere(
    (b) => b.type == 'promo_grid_0',
    orElse: () => _defaultPromoGrid0,
  );
  BannerModel get promoGrid1 => _banners.firstWhere(
    (b) => b.type == 'promo_grid_1',
    orElse: () => _defaultPromoGrid1,
  );
  BannerModel get promoGrid2 => _banners.firstWhere(
    (b) => b.type == 'promo_grid_2',
    orElse: () => _defaultPromoGrid2,
  );
  BannerModel get promoGrid3 => _banners.firstWhere(
    (b) => b.type == 'promo_grid_3',
    orElse: () => _defaultPromoGrid3,
  );
  List<BannerModel> get promoBanners =>
      _banners.where((b) => b.type == 'promo').toList();

  static final _defaultSideTop = BannerModel(
    id: 'default_top',
    title: 'COLORFUL PILLOWS',
    subtitle: 'Starts at ₹299',
    imageUrl: 'assets/images/colorful_pillows_promo.png',
    link: '/',
    tag: 'Trending',
    type: 'side_top',
    bgColor: '#3B82F6',
  );

  static final _defaultSideBottom = BannerModel(
    id: 'default_bottom',
    title: 'INTERIOR DESIGN',
    subtitle: '₹499',
    imageUrl: 'assets/images/interior_design_promo.png',
    link: '/',
    tag: 'Premium',
    type: 'side_bottom',
    bgColor: '#14B8A6',
  );

  static final _defaultOfferBanner = BannerModel(
    id: 'default_offer',
    title: 'Get 50% OFF Your First Order',
    subtitle:
        'Discover amazing deals on premium products. Limited time offer for new customers only!',
    imageUrl: '', // This one uses a gradient background in the component
    link: '/',
    tag: 'LIMITED TIME',
    type: 'offer',
    bgColor: '#F59E0B',
  );

  static final _defaultTrendingBanner = BannerModel(
    id: 'default_trending',
    title: 'ARMCHAIR FURNITURE',
    subtitle: 'up to 50% OFF',
    imageUrl:
        'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800',
    link: '/',
    tag: 'Trending',
    type: 'trending',
    bgColor: '#8B5CF6',
  );

  static final _defaultSummerSaleBanner = BannerModel(
    id: 'default_summer_sale',
    title: 'Summer Sale - Up to 50% Off on Selected Items',
    subtitle: 'Hot Deal',
    imageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1400',
    link: '/shop',
    tag: 'Hot Deal',
    type: 'summer_sale',
    bgColor: '#EF4444',
  );

  static final _defaultBecomeVendorBanner = BannerModel(
    id: 'default_become_vendor',
    title: 'Become a Vendor.\nGrow Your Business With Us.',
    subtitle: 'Get your storefront, reach millions of customers, and enjoy fast payouts, promotion tools, and dedicated support.',
    imageUrl: 'https://ik.imagekit.io/xgdosezi9/banners/banner_1781869135292__XRIzd1zQ.png',
    link: '/become-vendor',
    tag: '20% FLAT DISCOUNT',
    type: 'become_vendor',
    bgColor: '#0F766E',
  );

  static final _defaultVendorAuthBanner = BannerModel(
    id: 'default_vendor_auth',
    title: 'Vendor Auth Page Banner',
    subtitle: '',
    imageUrl: 'assets/images/auth.png',
    link: '/',
    tag: '',
    type: 'vendor_auth',
    bgColor: '#3B82F6',
  );

  static final _defaultResellerAuthBanner = BannerModel(
    id: 'default_reseller_auth',
    title: 'Reseller Auth Page Banner',
    subtitle: '',
    imageUrl: 'assets/images/auth2.png',
    link: '/',
    tag: '',
    type: 'reseller_auth',
    bgColor: '#3B82F6',
  );

  static final _defaultPromoGrid0 = BannerModel(
    id: 'default_promo_grid_0',
    title: 'Beauty & Personal Care',
    subtitle: 'Beauty & Personal Care',
    imageUrl: '',
    link: '/shop',
    tag: 'BEST SALE',
    type: 'promo_grid_0',
    bgColor: '#3B82F6',
  );

  static final _defaultPromoGrid1 = BannerModel(
    id: 'default_promo_grid_1',
    title: 'Toys & Games',
    subtitle: 'Toys & Games',
    imageUrl: '',
    link: '/shop',
    tag: 'NEW ARRIVAL',
    type: 'promo_grid_1',
    bgColor: '#FFA500',
  );

  static final _defaultPromoGrid2 = BannerModel(
    id: 'default_promo_grid_2',
    title: 'Gadgets',
    subtitle: 'Gadgets',
    imageUrl: '',
    link: '/shop',
    tag: 'OFF 15%',
    type: 'promo_grid_2',
    bgColor: '#10B981',
  );

  static final _defaultPromoGrid3 = BannerModel(
    id: 'default_promo_grid_3',
    title: 'Books & Stationery',
    subtitle: 'Books & Stationery',
    imageUrl: '',
    link: '/shop',
    tag: 'FREE SHIPPING',
    type: 'promo_grid_3',
    bgColor: '#6B21A8',
  );

  Future<void> init() async {
    await fetchData();

    // Listen for category updates
    SocketService.instance.on('category', (data) {
      debugPrint('Category socket update: ${data['action']}');
      fetchCategories();
    });

    // Listen for product updates
    SocketService.instance.on('product', (data) {
      debugPrint('Product socket update: ${data['action']}');
      fetchProducts();
    });

    // Listen for banner updates
    SocketService.instance.on('admin_data_updated', (data) {
      if (data['type'] == 'banner') {
        debugPrint('Banner socket update received');
        fetchBanners();
      }
    });
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([fetchCategories(), fetchProducts(), fetchBanners()]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/home/banners'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bannerList = data['data'] ?? [];
        _banners = bannerList.map((j) => BannerModel.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/home/categories?type=approved&tree=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _categories = data['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/home/products'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allProducts = data['data'] ?? [];
        _products = allProducts.where((p) => p['status'] == 'Active').toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }
}
