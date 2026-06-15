import 'package:get_it/get_it.dart';
import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/features/vendors/data/services/vendor_service.dart';
import 'package:ojas_admin/features/banners/data/services/banner_service.dart';
import 'package:ojas_admin/features/categories/data/services/category_service.dart';
import 'package:ojas_admin/features/users/data/services/user_service.dart';
import 'package:ojas_admin/core/services/product_service.dart';
import 'package:ojas_admin/features/auth/data/services/auth_service.dart';
import 'package:ojas_admin/features/subcategories/data/services/subcategory_service.dart';
import 'package:ojas_admin/features/dashboard/data/services/dashboard_service.dart';
import 'package:ojas_admin/features/help/data/services/admin_support_service.dart';
import 'package:ojas_admin/features/admins/data/services/admin_management_service.dart';
import 'package:ojas_admin/core/services/global_search_service.dart';
import 'package:ojas_admin/core/services/favicon_helper.dart';
import 'package:ojas_admin/features/resellers/data/services/reseller_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Global Search Service
  if (!sl.isRegistered<GlobalSearchService>()) {
    sl.registerLazySingleton(() => GlobalSearchService());
  }

  // Services
  if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton(() => ApiService());
  }

  if (!sl.isRegistered<AuthService>()) {
    sl.registerLazySingleton(() => AuthService(sl()));
  }

  if (!sl.isRegistered<VendorService>()) {
    sl.registerLazySingleton(() => VendorService(sl()));
  }

  if (!sl.isRegistered<UserService>()) {
    sl.registerLazySingleton(() => UserService(sl()));
  }

  if (!sl.isRegistered<ResellerService>()) {
    sl.registerLazySingleton(() => ResellerService(sl()));
  }

  if (!sl.isRegistered<BannerService>()) {
    sl.registerLazySingleton(() => BannerService(sl()));
  }

  if (!sl.isRegistered<CategoryService>()) {
    sl.registerLazySingleton(() => CategoryService());
  }

  if (!sl.isRegistered<SubcategoryService>()) {
    sl.registerLazySingleton(() => SubcategoryService());
  }

  if (!sl.isRegistered<ProductService>()) {
    sl.registerLazySingleton(() => ProductService(sl()));
  }

  if (!sl.isRegistered<DashboardService>()) {
    sl.registerLazySingleton(() => DashboardService(sl()));
  }

  if (!sl.isRegistered<AdminSupportService>()) {
    sl.registerLazySingleton(() => AdminSupportService());
  }

  if (!sl.isRegistered<AdminManagementService>()) {
    sl.registerLazySingleton(() => AdminManagementService(sl()));
  }

  // Fetch and update favicon on start
  _loadFavicon();
}

void _loadFavicon() async {
  try {
    final apiService = sl<ApiService>();
    final response = await apiService.dio.get('/settings');
    if (response.statusCode == 200) {
      final data = response.data['data'];
      final faviconUrl = data['favicon'];
      if (faviconUrl != null && faviconUrl.isNotEmpty) {
        updateFavicon(faviconUrl);
      }
    }
  } catch (e) {
    print('Error loading favicon on start: $e');
  }
}
