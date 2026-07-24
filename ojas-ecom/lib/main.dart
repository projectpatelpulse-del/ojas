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
        final isProductPath =
            pathSegments.length == 2 && pathSegments[0] == 'product';

        final ref = uri.queryParameters['ref'];
        if (ref != null) {
          final id = path == '/product-detail'
              ? uri.queryParameters['id']
              : (pathSegments.length == 2 ? pathSegments[1] : null);

          if (id != null) {
            SessionService.instance.setReferral(ref, id);
          }
        }

        // Commented out referral redirect hijacking logic.
        // Previously, if refCode was present in session, navigating to '/' or other unallowed paths
        // would forcibly redirect user to the referred ProductDetailPage instead of home page.
        // if (SessionService.instance.refCode != null) {
        //   final allowedPaths = {
        //     '/product-detail',
        //     '/cart',
        //     '/login',
        //     '/register',
        //     '/welcome',
        //     '/profile',
        //     '/orders',
        //     '/returns',
        //     '/terms',
        //     '/privacy',
        //     '/contact',
        //   };
        // 
        //   if (!allowedPaths.contains(path) && !isProductPath) {
        //     final targetProductId =
        //         SessionService.instance.referredProductId;
        // 
        //     if (targetProductId != null) {
        //       return MaterialPageRoute(
        //         settings: RouteSettings(
        //           name:
        //               '/product-detail?id=$targetProductId&ref=${SessionService.instance.refCode}',
        //         ),
        //         builder: (context) => ProductDetailPage(
        //           productId: targetProductId,
        //           refCode: SessionService.instance.refCode,
        //         ),
        //       );
        //     }
        //   }
        // }

        if (path == '/product-detail' || isProductPath) {
          ProductModel? product;

          if (routeSettings.arguments is ProductModel) {
            product = routeSettings.arguments as ProductModel;
          } else {
            final id = path == '/product-detail'
                ? uri.queryParameters['id']
                : pathSegments[1];

            if (id != null) {
              final found = HomeController.instance.products.firstWhere(
                (p) => p['_id'] == id,
                orElse: () => null,
              );

              if (found != null) {
                product = ProductModel.fromMap(found);
              }
            }
          }

          final id = path == '/product-detail'
              ? uri.queryParameters['id']
              : (pathSegments.length == 2 ? pathSegments[1] : null);

          final refCodeVal =
              ref ?? uri.queryParameters['ref'] ?? SessionService.instance.refCode;

          return MaterialPageRoute(
            settings: routeSettings,
            builder: (context) => ProductDetailPage(
              product: product,
              productId: id,
              refCode: refCodeVal,
            ),
          );
        }

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
