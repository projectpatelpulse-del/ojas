import 'package:get_it/get_it.dart';
import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/services/favicon_helper.dart';
import 'package:ojas_vendor/features/products/data/services/product_service.dart';
import 'package:ojas_vendor/features/settings/data/services/vendor_settings_service.dart';
import 'package:ojas_vendor/features/categories/data/services/category_service.dart';
import 'package:ojas_vendor/features/help/data/services/support_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => ProductService(sl()));
  sl.registerLazySingleton(() => VendorSettingsService());
  sl.registerLazySingleton(() => CategoryService(sl()));
  sl.registerLazySingleton(() => SupportService());

  // Fetch and update favicon on start
  _loadFavicon();
}

void _loadFavicon() async {
  try {
    final apiService = sl<ApiService>();
    final response = await apiService.dio.get('/home/settings');
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
