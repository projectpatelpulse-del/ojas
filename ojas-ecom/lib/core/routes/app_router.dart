import 'package:flutter/material.dart';
export 'package:go_router/go_router.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/core/utils/url_helper.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/cart/presentation/pages/cart_page.dart';
import 'package:ojas_user/features/cart/presentation/pages/order_success_page.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/home/presentation/pages/about_us_page.dart';
import 'package:ojas_user/features/home/presentation/pages/become_reseller_page.dart';
import 'package:ojas_user/features/home/presentation/pages/become_vendor_page.dart';
import 'package:ojas_user/features/home/presentation/pages/blog_page.dart';
import 'package:ojas_user/features/home/presentation/pages/contact_page.dart';
import 'package:ojas_user/features/home/presentation/pages/deals_page.dart';
import 'package:ojas_user/features/home/presentation/pages/features_page.dart';
import 'package:ojas_user/features/home/presentation/pages/home_page.dart';
import 'package:ojas_user/features/home/presentation/pages/orders_page.dart';
import 'package:ojas_user/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:ojas_user/features/home/presentation/pages/product_detail_page.dart';
import 'package:ojas_user/features/home/presentation/pages/returns_refunds_page.dart';
import 'package:ojas_user/features/home/presentation/pages/shared_collection_page.dart';
import 'package:ojas_user/features/home/presentation/pages/shop_page.dart';
import 'package:ojas_user/features/home/presentation/pages/terms_conditions_page.dart';
import 'package:ojas_user/features/home/presentation/pages/wishlist_page.dart';

import '../../features/auth/presentation/pages/auth_screen.dart';
import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/auth/presentation/pages/welcome_screen.dart';
import 'app_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Helper to push a route onto the stack (maintains back history)
  static void push(BuildContext context, String location, {Object? extra}) {
    GoRouter.of(context).push(location, extra: extra);
  }

  /// Helper to replace the top route or go to root
  static void go(BuildContext context, String location, {Object? extra}) {
    GoRouter.of(context).go(location, extra: extra);
  }

  /// Helper to pop the top route
  static void pop(BuildContext context, [dynamic result]) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop(result);
    } else {
      GoRouter.of(context).go('/');
    }
  }

  /// Helper to push product detail page with full stack tracking
  static void pushProduct(BuildContext context, dynamic product, {String? refCode}) {
    final route = UrlHelper.productUrl(product, refCode: refCode);
    GoRouter.of(context).push(route, extra: product);
  }

  /// Helper to navigate to category / subcategory
  static void pushCategory(BuildContext context, String? category, [String? subcategory]) {
    if (category == null || category.trim().isEmpty || category == 'All') {
      GoRouter.of(context).push('/shop');
      return;
    }
    final route = UrlHelper.categoryUrl(category, subcategory);
    GoRouter.of(context).push(
      route,
      extra: {
        'category': category,
        if (subcategory != null) 'subcategory': subcategory,
      },
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // 1. Home
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),

      // 2. Features
      GoRoute(
        path: '/features',
        builder: (context, state) => const FeaturesPage(),
      ),

      // 3. Deals
      GoRoute(
        path: '/deals',
        builder: (context, state) => const DealsPage(),
      ),

      // 4. Shop / Categories
      GoRoute(
        path: '/shop',
        builder: (context, state) {
          final extraMap = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          final category = extraMap?['category'] ?? state.uri.queryParameters['category'];
          final subcategory = extraMap?['subcategory'] ?? state.uri.queryParameters['subcategory'];
          final search = extraMap?['search'] ?? state.uri.queryParameters['search'] ?? state.uri.queryParameters['q'];

          return ShopPage(
            initialCategory: category,
            initialSubCategory: subcategory,
            initialSearch: search,
          );
        },
      ),
      GoRoute(
        path: '/shop/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'];
          final subcategory = state.uri.queryParameters['subcategory'];
          final search = state.uri.queryParameters['search'] ?? state.uri.queryParameters['q'];

          return ShopPage(
            initialCategory: category,
            initialSubCategory: subcategory,
            initialSearch: search,
          );
        },
      ),
      GoRoute(
        path: '/shop/:category/:subcategory',
        builder: (context, state) {
          final category = state.pathParameters['category'];
          final subcategory = state.pathParameters['subcategory'];
          final search = state.uri.queryParameters['search'] ?? state.uri.queryParameters['q'];

          return ShopPage(
            initialCategory: category,
            initialSubCategory: subcategory,
            initialSearch: search,
          );
        },
      ),

      // Category redirects to /shop
      GoRoute(
        path: '/category/:category',
        redirect: (context, state) => '/shop/${state.pathParameters['category']}',
      ),
      GoRoute(
        path: '/category/:category/:subcategory',
        redirect: (context, state) => '/shop/${state.pathParameters['category']}/${state.pathParameters['subcategory']}',
      ),

      // 5. Product Detail Page
      GoRoute(
        path: '/product-detail',
        builder: (context, state) => _buildProductDetailPage(context, state),
      ),
      GoRoute(
        path: '/product/:p1',
        builder: (context, state) => _buildProductDetailPage(context, state),
      ),
      GoRoute(
        path: '/product/:p1/:p2',
        builder: (context, state) => _buildProductDetailPage(context, state),
      ),
      GoRoute(
        path: '/product/:p1/:p2/:p3',
        builder: (context, state) => _buildProductDetailPage(context, state),
      ),
      GoRoute(
        path: '/product/:p1/:p2/:p3/:p4',
        builder: (context, state) => _buildProductDetailPage(context, state),
      ),

      // 6. Cart & Checkout
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          final orderId = state.uri.queryParameters['orderId'] ?? extra?['orderId']?.toString();
          final amount = state.uri.queryParameters['amount'] ?? extra?['amount']?.toString();
          final paymentMethod = state.uri.queryParameters['payment'] ?? extra?['paymentMethod']?.toString();
          final referralCode = state.uri.queryParameters['ref'] ?? extra?['referralCode']?.toString();
          final referredProductId = state.uri.queryParameters['refProduct'] ?? extra?['referredProductId']?.toString();
          final shippingAddress = extra?['shippingAddress'] is Map<String, dynamic> ? extra!['shippingAddress'] as Map<String, dynamic> : null;

          return OrderSuccessPage(
            orderId: orderId,
            amount: amount,
            paymentMethod: paymentMethod,
            referralCode: referralCode,
            referredProductId: referredProductId,
            shippingAddress: shippingAddress,
          );
        },
      ),
      GoRoute(
        path: '/thank-you',
        redirect: (context, state) => '/order-success${state.uri.hasQuery ? '?${state.uri.query}' : ''}',
      ),
      GoRoute(
        path: '/order-placed',
        redirect: (context, state) => '/order-success${state.uri.hasQuery ? '?${state.uri.query}' : ''}',
      ),

      // 7. Vendor / Reseller
      GoRoute(
        path: '/become-vendor',
        builder: (context, state) => const BecomeVendorPage(),
      ),
      GoRoute(
        path: '/become-reseller',
        builder: (context, state) => const BecomeResellerPage(),
      ),

      // 8. Wishlist
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistPage(),
      ),

      // 9. Blog
      GoRoute(
        path: '/blog',
        builder: (context, state) => const BlogPage(),
      ),

      // 10. Orders
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersPage(),
      ),

      // 11. Static Info Pages
      GoRoute(
        path: '/returns',
        builder: (context, state) => const ReturnsRefundsPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/about-us',
        builder: (context, state) => const AboutUsPage(),
      ),

      // 12. Authentication
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(isInitialLogin: true),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const AuthScreen(isInitialLogin: false),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) {
          final user = state.extra is UserModel
              ? state.extra as UserModel
              : SessionService.instance.currentUser;
          if (user == null) return const AuthScreen(isInitialLogin: true);
          return WelcomeScreen(user: user);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final user = state.extra is UserModel
              ? state.extra as UserModel
              : SessionService.instance.currentUser;
          if (user == null) return const AuthScreen(isInitialLogin: true);
          return ProfileScreen(user: user);
        },
      ),

      // 13. Shared Collection
      GoRoute(
        path: '/collection',
        builder: (context, state) => SharedCollectionPage(
          shareCode: state.uri.queryParameters['shareCode'] ?? '',
        ),
      ),
      GoRoute(
        path: '/collection/:shareCode',
        builder: (context, state) => SharedCollectionPage(
          shareCode: state.pathParameters['shareCode'] ?? '',
        ),
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('404 / Unknown route requested: ${state.uri}');
      return const HomePage();
    },
  );

  static Widget _buildProductDetailPage(BuildContext context, GoRouterState state) {
    ProductModel? product;
    String? identifier;
    String? initialVariation = state.uri.queryParameters['variation'] ??
        state.uri.queryParameters['v'] ??
        state.uri.queryParameters['sku'];

    final uri = state.uri;
    final pathSegments = uri.pathSegments;
    final ref = uri.queryParameters['ref'];

    final all = HomeController.instance.products.isNotEmpty
        ? HomeController.instance.products
        : HomeController.instance.shopProducts;

    bool matchesProduct(dynamic p, String seg) {
      if (p is ProductModel) {
        final idStr = p.id;
        final slugStr = p.slug ?? '';
        final nameStr = p.name;
        final titleStr = p.title;
        return idStr == seg ||
            slugStr == seg ||
            UrlHelper.matchesSlug(slugStr, seg) ||
            UrlHelper.matchesSlug(nameStr, seg) ||
            UrlHelper.matchesSlug(titleStr, seg);
      }
      if (p is Map) {
        final idStr = (p['_id'] ?? p['id'] ?? '').toString();
        final slugStr = (p['slug'] ?? '').toString();
        final nameStr = (p['name'] ?? '').toString();
        final titleStr = (p['title'] ?? '').toString();
        return idStr == seg ||
            slugStr == seg ||
            UrlHelper.matchesSlug(slugStr, seg) ||
            UrlHelper.matchesSlug(nameStr, seg) ||
            UrlHelper.matchesSlug(titleStr, seg);
      }
      return false;
    }

    if (state.extra is ProductModel) {
      product = state.extra as ProductModel;
      identifier = product.id;
    } else if (state.extra is Map<String, dynamic>) {
      try {
        product = ProductModel.fromMap(Map<String, dynamic>.from(state.extra as Map));
        identifier = product.id;
      } catch (_) {}
    }

    if (product == null) {
      if (uri.path == '/product-detail') {
        identifier = uri.queryParameters['id'];
      } else if (pathSegments.isNotEmpty) {
        final lastSeg = pathSegments.last;
        final foundDirect = all.firstWhere((p) => matchesProduct(p, lastSeg), orElse: () => null);

        if (foundDirect != null) {
          identifier = lastSeg;
          try {
            product = ProductModel.fromMap(Map<String, dynamic>.from(foundDirect));
          } catch (_) {}
        } else if (pathSegments.length >= 2) {
          final secondLastSeg = pathSegments[pathSegments.length - 2];
          final foundParent = all.firstWhere((p) => matchesProduct(p, secondLastSeg), orElse: () => null);

          if (foundParent != null) {
            identifier = secondLastSeg;
            initialVariation ??= lastSeg;
            try {
              product = ProductModel.fromMap(Map<String, dynamic>.from(foundParent));
            } catch (_) {}
          } else {
            identifier = lastSeg;
          }
        } else {
          identifier = lastSeg;
        }
      }
    }

    if (identifier == null && pathSegments.isNotEmpty) {
      identifier = pathSegments.last;
    }

    final targetId = product?.id ?? identifier;
    final refCodeVal = ref ?? SessionService.instance.refCode;

    if (refCodeVal != null && targetId != null) {
      SessionService.instance.setReferral(refCodeVal, targetId);
    }

    return ProductDetailPage(
      key: ValueKey(targetId ?? state.uri.toString()),
      product: product,
      productId: targetId,
      refCode: refCodeVal,
      initialVariation: initialVariation,
    );
  }
}
