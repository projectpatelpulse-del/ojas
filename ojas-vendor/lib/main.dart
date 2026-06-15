import 'package:flutter/material.dart';
import 'package:ojas_vendor/core/routing/app_router.dart';
import 'package:ojas_vendor/core/theme/app_theme.dart';
import 'package:ojas_vendor/core/services/service_locator.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const OjasVendorApp());
}

class OjasVendorApp extends StatelessWidget {
  const OjasVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ojas Vendor Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
