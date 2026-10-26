import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:ojas_user/core/services/socket_service.dart';
import 'package:ojas_user/core/controllers/settings_controller.dart';
import 'package:ojas_user/core/controllers/home_controller.dart';
import 'package:ojas_user/core/controllers/wishlist_controller.dart';
import 'package:ojas_user/core/theme/app_theme.dart';
import 'package:ojas_user/features/home/presentation/pages/home_page.dart';
import 'package:ojas_user/features/home/presentation/pages/features_page.dart';
import 'package:ojas_user/features/home/presentation/pages/deals_page.dart';
import 'package:ojas_user/features/home/presentation/pages/shop_page.dart';
import 'package:ojas_user/features/home/presentation/pages/about_us_page.dart';
import 'package:ojas_user/features/home/presentation/pages/blog_page.dart';
import 'package:ojas_user/features/home/presentation/pages/become_vendor_page.dart';
import 'package:ojas_user/features/home/presentation/pages/become_reseller_page.dart';
import 'package:ojas_user/features/home/presentation/pages/product_detail_page.dart';
import 'package:ojas_user/features/home/domain/models/product_model.dart';
import 'package:ojas_user/features/auth/presentation/pages/auth_screen.dart';
import 'package:ojas_user/features/auth/presentation/pages/profile_screen.dart';
import 'package:ojas_user/features/auth/presentation/pages/welcome_screen.dart';
import 'package:ojas_user/features/home/presentation/pages/wishlist_page.dart';
import 'package:ojas_user/features/home/presentation/pages/orders_page.dart';
import 'package:ojas_user/features/home/presentation/pages/returns_refunds_page.dart';
import 'package:ojas_user/features/home/presentation/pages/terms_conditions_page.dart';
import 'package:ojas_user/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:ojas_user/features/home/presentation/pages/contact_page.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/cart/presentation/pages/cart_page.dart';
import 'package:ojas_user/features/home/presentation/pages/shared_collection_page.dart';

import 'package:ojas_user/core/utils/url_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sizer/sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC2StOCcAiACVKZg1G4d1k-zyl1YxctVcQ",
      authDomain: "ojas-app-d0bc6.firebaseapp.com",
      projectId: "ojas-app-d0bc6",
      storageBucket: "ojas-app-d0bc6.firebasestorage.app",
      messagingSenderId: "25163277339",
      appId: "1:25163277339:web:90cc45ebf7f2189b4bc4be",
      measurementId: "G-ZYKJ1CH89N",
    ),
  );

  await SessionService.instance.initSession();
  
  // Initialize Real-time services
  SocketService.instance.init();
  await SettingsController.instance.init();
  await HomeController.instance.init();
  await WishlistController.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsController.instance),
        ChangeNotifierProvider.value(value: HomeController.instance),
        ChangeNotifierProvider.value(value: WishlistController.instance),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([
          SettingsController.instance,
          HomeController.instance,
          WishlistController.instance,
        ]),
        builder: (context, _) {
          final settings = SettingsController.instance.settings;
          
          final routes = {
            '/': (context) => const HomePage(),
            '/features': (context) => const FeaturesPage(),
            '/deals': (context) => const DealsPage(),
            '/shop': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Map<String, dynamic>) {
                return ShopPage(
                  initialCategory: args['category'],
                  initialSubCategory: args['subcategory'],
                  initialSearch: args['search'],
                );
              }
              return const ShopPage();
            },
            '/cart': (context) => const CartPage(),
            '/become-vendor': (context) => const BecomeVendorPage(),
            '/become-reseller': (context) => const BecomeResellerPage(),
            '/wishlist': (context) => const WishlistPage(),
            '/blog': (context) => const BlogPage(),
            '/orders': (context) => const OrdersPage(),
            '/returns': (context) => const ReturnsRefundsPage(),
            '/terms': (context) => const TermsConditionsPage(),
            '/privacy': (context) => const PrivacyPolicyPage(),
            '/contact': (context) => const ContactPage(),
            '/about-us': (context) => const AboutUsPage(),
            '/login': (context) => const AuthScreen(isInitialLogin: true),
            '/register': (context) => const AuthScreen(isInitialLogin: false),
            '/welcome': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              final user = args is UserModel ? args : SessionService.instance.currentUser;
              if (user == null) return const AuthScreen(isInitialLogin: true);
              return WelcomeScreen(user: user);
            },
            '/profile': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              final user = args is UserModel ? args : SessionService.instance.currentUser;
              if (user == null) return const AuthScreen(isInitialLogin: true);
              return ProfileScreen(user: user);
            },
          };

   return Sizer(
  builder: (context, orientation, deviceType) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: settings.marketplaceName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      onGenerateRoute: (routeSettings) {
        final name = routeSettings.name ?? '/';
        final uri = Uri.parse(name);
        final path = uri.path;
        final pathSegments = uri.pathSegments;

        // Check if referral code is present
        final ref = uri.queryParameters['ref'];

        // Reserved static route prefixes
        const reservedRoutes = {
          '',
          'features',
          'deals',
          'shop',
          'cart',
          'become-vendor',
          'become-reseller',
          'wishlist',
          'blog',
          'orders',
          'returns',
          'terms',
          'privacy',
          'contact',
          'about-us',
          'login',
          'register',
          'welcome',
          'profile',
          'collection',
          'category',
          'product',
          'product-detail',
        };

        // 1. Product Detail Page
        // Matches:
        // - /product-detail?id=...
        // - /product/:idOrSlug
        // - /product/:categorySlug/:idOrSlug
        // - /product/:categorySlug/:subCategorySlug/:idOrSlug
        // - /:categorySlug/:subCategorySlug/:idOrSlug (when segments == 3 and segment[0] not reserved)
        final isProductPrefix = pathSegments.isNotEmpty && pathSegments[0] == 'product';
        final isProductDetailRoute = path == '/product-detail';
        final is3SegmentCustomProduct = pathSegments.length == 3 && !reservedRoutes.contains(pathSegments[0]);

        if (isProductDetailRoute || isProductPrefix || is3SegmentCustomProduct) {
          ProductModel? product;
          final identifier = isProductDetailRoute
              ? uri.queryParameters['id']
              : pathSegments.last;

          if (routeSettings.arguments is ProductModel) {
            product = routeSettings.arguments as ProductModel;
          } else if (identifier != null && identifier.isNotEmpty) {
            final all = HomeController.instance.products.isNotEmpty
                ? HomeController.instance.products
                : HomeController.instance.shopProducts;
            final found = all.firstWhere(
              (p) {
                final idStr = (p['_id'] ?? p['id'] ?? '').toString();
                final slugStr = (p['slug'] ?? '').toString();
                final nameStr = (p['name'] ?? '').toString();
                final titleStr = (p['title'] ?? '').toString();
                return idStr == identifier ||
                       slugStr == identifier ||
                       UrlHelper.matchesSlug(slugStr, identifier) ||
                       UrlHelper.matchesSlug(nameStr, identifier) ||
                       UrlHelper.matchesSlug(titleStr, identifier);
              },
              orElse: () => null,
            );

            if (found != null) {
              try {
                product = ProductModel.fromMap(Map<String, dynamic>.from(found));
              } catch (_) {}
            }
          }

          final targetId = product?.id ?? identifier;
          final refCodeVal = ref ?? SessionService.instance.refCode;

          if (refCodeVal != null && targetId != null) {
            SessionService.instance.setReferral(refCodeVal, targetId);
          }

          return MaterialPageRoute(
            settings: routeSettings,
            builder: (context) => ProductDetailPage(
              product: product,
              productId: targetId,
              refCode: refCodeVal,
            ),
          );
        }

        // 2. Collection Route
        final isCollectionPath = pathSegments.length == 2 && pathSegments[0] == 'collection';
        if (path == '/collection' || isCollectionPath) {
          final shareCode = path == '/collection'
              ? uri.queryParameters['shareCode']
              : pathSegments[1];

          return MaterialPageRoute(
            settings: routeSettings,
            builder: (context) => SharedCollectionPage(
              shareCode: shareCode ?? "",
            ),
          );
        }

        // 3. Shop / Category / Subcategory Route
        // Matches:
        // - /shop
        // - /shop/:category
        // - /shop/:category/:subcategory
        // - /category/:category
        // - /category/:category/:subcategory
        // - /:category (when 1 segment and not reserved)
        // - /:category/:subcategory (when 2 segments and not reserved)
        final isShopPrefix = pathSegments.isNotEmpty && (pathSegments[0] == 'shop' || pathSegments[0] == 'category');
        final isCustomCategoryRoute = (pathSegments.length == 1 || pathSegments.length == 2) &&
            pathSegments.isNotEmpty &&
            !reservedRoutes.contains(pathSegments[0]);

        if (path == '/shop' || isShopPrefix || isCustomCategoryRoute) {
          String? category;
          String? subcategory;
          String? search = uri.queryParameters['search'] ?? uri.queryParameters['q'];

          if (routeSettings.arguments is Map<String, dynamic>) {
            final args = routeSettings.arguments as Map<String, dynamic>;
            category = args['category'];
            subcategory = args['subcategory'];
            search = args['search'] ?? search;
          } else {
            if (isShopPrefix) {
              category = pathSegments.length > 1 ? pathSegments[1] : null;
              subcategory = pathSegments.length > 2 ? pathSegments[2] : null;
            } else if (isCustomCategoryRoute) {
              category = pathSegments[0];
              subcategory = pathSegments.length > 1 ? pathSegments[1] : null;
            }
            category ??= uri.queryParameters['category'];
            subcategory ??= uri.queryParameters['subcategory'];
          }

          return MaterialPageRoute(
            settings: routeSettings,
            builder: (context) => ShopPage(
              initialCategory: category,
              initialSubCategory: subcategory,
              initialSearch: search,
            ),
          );
        }

        // 4. Other Standard Routes
        final builder = routes[path];
        if (builder != null) {
          return MaterialPageRoute(
            settings: routeSettings,
            builder: builder,
          );
        }

        return null;
      },
    );
  },
);
          // MaterialApp(
          //   navigatorKey: _navigatorKey,
          //   debugShowCheckedModeBanner: false,
          //   title: settings.marketplaceName,
          //   theme: AppTheme.lightTheme,
          //   darkTheme: AppTheme.darkTheme,
          //   themeMode: ThemeMode.dark,
          //   initialRoute: '/',
          //   onGenerateRoute: (routeSettings) {
          //     final name = routeSettings.name ?? '/';
          //     final uri = Uri.parse(name);
          //     final path = uri.path;

          //     final pathSegments = uri.pathSegments;
          //     final isProductPath = pathSegments.length == 2 && pathSegments[0] == 'product';

          //     final ref = uri.queryParameters['ref'];
          //     if (ref != null) {
          //       final id = path == '/product-detail' ? uri.queryParameters['id'] : (pathSegments.length == 2 ? pathSegments[1] : null);
          //       if (id != null) {
          //         SessionService.instance.setReferral(ref, id);
          //       }
          //     }

          //     if (SessionService.instance.refCode != null) {
          //       final allowedPaths = {
          //         '/product-detail',
          //         '/cart',
          //         '/login',
          //         '/register',
          //         '/welcome',
          //         '/profile',
          //         '/orders',
          //         '/returns',
          //         '/terms',
          //         '/privacy',
          //         '/contact',
          //       };
          //       if (!allowedPaths.contains(path) && !isProductPath) {
          //         final targetProductId = SessionService.instance.referredProductId;
          //         if (targetProductId != null) {
          //           return MaterialPageRoute(
          //             settings: RouteSettings(
          //               name: '/product-detail?id=$targetProductId&ref=${SessionService.instance.refCode}',
          //             ),
          //             builder: (context) => ProductDetailPage(
          //               productId: targetProductId,
          //               refCode: SessionService.instance.refCode,
          //             ),
          //           );
          //         }
          //       }
          //     }

          //     if (path == '/product-detail' || isProductPath) {
          //       ProductModel? product;
          //       if (routeSettings.arguments is ProductModel) {
          //         product = routeSettings.arguments as ProductModel;
          //       } else {
          //         final id = path == '/product-detail' ? uri.queryParameters['id'] : pathSegments[1];
          //         if (id != null) {
          //           final found = HomeController.instance.products.firstWhere(
          //             (p) => p['_id'] == id,
          //             orElse: () => null,
          //           );
          //           if (found != null) {
          //             product = ProductModel.fromMap(found);
          //           }
          //         }
          //       }

          //       final id = path == '/product-detail' ? uri.queryParameters['id'] : (pathSegments.length == 2 ? pathSegments[1] : null);
          //       final refCodeVal = ref ?? uri.queryParameters['ref'] ?? SessionService.instance.refCode;

          //       return MaterialPageRoute(
          //         settings: routeSettings,
          //         builder: (context) => ProductDetailPage(
          //           product: product,
          //           productId: id,
          //           refCode: refCodeVal,
          //         ),
          //       );
          //     }

          //     final builder = routes[path];
          //     if (builder != null) {
          //       return MaterialPageRoute(
          //         settings: routeSettings,
          //         builder: builder,
          //       );
          //     }
          //     return null;
          //   },
          // );
      
      
        },
      ),
    );
  }
}
