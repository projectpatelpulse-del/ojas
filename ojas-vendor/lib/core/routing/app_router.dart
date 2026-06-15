import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ojas_vendor/features/customers/presentation/pages/customers_page.dart';
import 'package:ojas_vendor/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ojas_vendor/features/orders/presentation/pages/orders_page.dart';
import 'package:ojas_vendor/features/products/presentation/pages/add_product_page.dart';
import 'package:ojas_vendor/features/products/presentation/pages/products_page.dart';
import 'package:ojas_vendor/features/categories/presentation/pages/categories_page.dart';
import 'package:ojas_vendor/features/subcategories/presentation/pages/subcategories_page.dart';
import 'package:ojas_vendor/features/discounts/presentation/pages/discounts_page.dart';
import 'package:ojas_vendor/features/discounts/presentation/pages/product_discounts_page.dart';
import 'package:ojas_vendor/features/settings/presentation/pages/settings_page.dart';
import 'package:ojas_vendor/features/analytics/presentation/pages/analytics_page.dart';
import 'package:ojas_vendor/features/help/presentation/pages/help_page.dart';
import 'package:ojas_vendor/features/auth/presentation/pages/login_page.dart';
import 'package:ojas_vendor/features/auth/presentation/pages/register_page.dart';
import 'package:ojas_vendor/features/payouts/presentation/pages/payout_page.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login', // Start at login to ensure credentials can be asked
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. SSO TOKEN CONSUMPTION (Only happens if token is in URL)
      final tokenFromUrl = state.uri.queryParameters['token'] ?? Uri.base.queryParameters['token'];
      if (tokenFromUrl != null && tokenFromUrl.isNotEmpty) {
        await prefs.setString('vendor_token', tokenFromUrl);
        
        // Fetch and store vendor info immediately after SSO
        try {
          final dio = sl<ApiService>().dio;
          // Set the token manually for this immediate request since the interceptor might not have picked it up yet from prefs
          dio.options.headers['Authorization'] = 'Bearer $tokenFromUrl';
          
          debugPrint('SSO: Fetching vendor settings with token: ${tokenFromUrl.substring(0, 10)}...');
          final response = await dio.get('/vendor/settings');
          
          if (response.statusCode == 200 && response.data['data'] != null) {
            final userData = response.data['data']['user'];
            if (userData != null) {
              final name = userData['name'] ?? 'Vendor';
              final email = userData['email'] ?? '';
              await prefs.setString('vendor_name', name);
              await prefs.setString('vendor_email', email);
              debugPrint('SSO: Successfully stored vendor info: $name ($email)');
            } else {
              debugPrint('SSO: User data was null in response');
            }
          } else {
            debugPrint('SSO: Failed to fetch settings, status: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('SSO: Error fetching vendor info during SSO: $e');
        }

        // Clear query params by navigating to dashboard
        return '/';
      }

      final savedToken = prefs.getString('vendor_token');
      final isOnLoginPage = state.uri.path == '/login';
      final isOnRegisterPage = state.uri.path == '/register';
      
      // 2. LOGIC FOR DIRECT ACCESS
      if (savedToken == null) {
        // No token → must be on login or register page
        if (isOnLoginPage || isOnRegisterPage) return null;
        return '/login';
      }

      // 3. IF WE HAVE A TOKEN:
      // If the user specifically navigated to /login, let them stay there (so they can enter credentials as requested!
      // This fixes the "why it's not asking for login credentials" issue.
      if (isOnLoginPage) {
        return null; 
      }

      // BACKGROUND VALIDATION (To ensure the session hasn't expired on the server)
      try {
        final dio = sl<ApiService>().dio;
        await dio.get('/vendor/dashboard');
        return null; // All good
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          await prefs.remove('vendor_token');
          return '/login';
        }
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersPage(),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductsPage(),
      ),
      GoRoute(
        path: '/products/add',
        name: 'add-product',
        builder: (context, state) => AddProductPage(product: state.extra),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/subcategories',
        name: 'subcategories',
        builder: (context, state) => const SubcategoriesPage(),
      ),
      GoRoute(
        path: '/discounts',
        name: 'discounts',
        builder: (context, state) => const DiscountsPage(),
      ),
      GoRoute(
        path: '/discounts/products',
        name: 'product-discounts',
        builder: (context, state) => const ProductDiscountsPage(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/payouts',
        name: 'payouts',
        builder: (context, state) => const PayoutPage(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('No route defined for \${state.uri}'),
      ),
    ),
  );
}
