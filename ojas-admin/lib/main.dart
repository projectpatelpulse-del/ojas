import 'package:flutter/material.dart';
import 'package:ojas_admin/core/theme/app_theme.dart';
import 'package:ojas_admin/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ojas_admin/features/orders/presentation/pages/orders_page.dart';
import 'package:ojas_admin/features/users/presentation/pages/users_page.dart';
import 'package:ojas_admin/features/admins/presentation/pages/admin_management_page.dart';
import 'package:ojas_admin/features/profile/presentation/pages/profile_page.dart';
import 'package:ojas_admin/features/settings/presentation/pages/settings_page.dart';
import 'package:ojas_admin/features/products/presentation/pages/products_page.dart';
import 'package:ojas_admin/features/categories/presentation/pages/categories_page.dart';
import 'package:ojas_admin/features/subcategories/presentation/pages/subcategories_page.dart';
import 'package:ojas_admin/features/vendors/presentation/pages/vendors_page.dart';
import 'package:ojas_admin/features/help/presentation/pages/help_page.dart';
import 'package:ojas_admin/features/auth/presentation/pages/login_page.dart';
import 'package:ojas_admin/features/banners/presentation/pages/banners_page.dart';
import 'package:ojas_admin/features/payouts/presentation/pages/payouts_page.dart';
import 'package:ojas_admin/features/resellers/presentation/pages/resellers_page.dart';

import 'package:ojas_admin/core/services/service_locator.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ojas Admin',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/': (context) => const DashboardPage(currentRoute: '/'),
        '/admin-overview': (context) => const DashboardPage(currentRoute: '/admin-overview'),
        '/admin-management': (context) => const AdminManagementPage(),
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/products': (context) => const ProductsPage(),
        '/categories': (context) => const CategoriesPage(),
        '/subcategories': (context) => const SubcategoriesPage(),
        '/orders': (context) => const OrdersPage(),
        '/users': (context) => const UsersPage(),
        '/vendors': (context) => const VendorsPage(),
        '/resellers': (context) => const ResellersPage(),
        '/banners': (context) => const BannersPage(),
        '/payouts': (context) => const PayoutsPage(),
        '/help': (context) => const HelpPage(),
      },
    );
  }
}
